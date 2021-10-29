# DEBUG: active debug mode
# DRY_RUN: skip all git push (can generate side effects)
#
# set a value in DEBUG variable to echo all commands
echo "DEBUG=${DEBUG}"
echo "DRY_RUN=${DRY_RUN}"

[ "true" = "${DEBUG}" ] && echo "Set DEBUG mode" && set -x
if [ "true" = "${DRY_RUN}" ]
then
	echo "Set DRY_RUN mode"
else
	unset DRY_RUN
fi

# Define a temporary output file
export JENKINS_OUT_FILE=$(mktemp)

# Some option for manven to be less verbose
alias mvn="mvn -ntp --batch-mode -q"

function error(){
	echo >&2
	echo "Execution error:" 1>&2
	echo ${1:=No error message} 1>&2
	exit 2
}

function endScript(){
	local msg=$1
	[ ! -z "${msg}" ] && echo "${msg}"

	if [ -s "${JENKINS_OUT_FILE}" ]
	then
		echo
		echo "--------------------------------------------------------------------"
		[ -z "${DRYN_RUN}" ] && echo "(DRY_RUN was set, nothing has been pushed to github.)" && echo
		cat ${JENKINS_OUT_FILE}
	fi

	exit 0
}

function head(){
	echo """
************************************************
* ${1}
************************************************
""" | tee ${JENKINS_OUT_FILE}
}

#
# Set BRANCH_NAME, can be set by Jenkins, if not retrieve with git.
#
function setBranchName(){
	[ -z ${BRANCH_NAME+x} ] && echo "BRANCH_NAME not set, retrieved from git..." && export BRANCH_NAME=$(git branch --show-current)

	# if still no branch checkout master
	[ -z ${BRANCH_NAME+x} ] && echo "BRANCH_NAME still not set, checkout master..." && git checkout master && export BRANCH_NAME=$(git branch --show-current)

	[ -z ${BRANCH_NAME+x} ] && error "BRANCH_NAME not set."

	echo "BRANCH_NAME=${BRANCH_NAME}" 
}

#
# Set GIT_REPOSITORY variable
#
function setGitRepository(){
	GIT_REPOSITORY=$(git config --get remote.origin.url | sed -e "s,\.git,, " | sed -e "s,.*github.com.\(.*\)/\(.*\),https://github.com/\1/\2/,")
}

#
# Set MAVEN_CURRENT_VERSION: version from the pom
#
function setMavenCurrentVersion(){
	local pom_file=$1
	[ ! -f ${pom_file:=pom.xml} ] && error "'${1}' file doesn't exist."
	export MAVEN_CURRENT_VERSION=$(mvn org.apache.maven.plugins:maven-help-plugin:3.2.0:evaluate -Dexpression=project.version -q -DforceStdout)
	echo "MAVEN_CURRENT_VERSION=${MAVEN_CURRENT_VERSION}"
}

#
# Update maven version
#
function mvnUpdateVersion(){
	[ -z "${1}" ] && error "Given version is empty '${1}'."
	mvn versions:set -DnewVersion="${1}"

	local connectors_versions_properties=(connectors-se.version common.version connectors-test-bom.version)
	for p in "${connectors_versions_properties[@]}"
	do
		mvn versions:set-property -Dproperty="${p}" -DnewVersion="${1}"
	done
}

#
# Set MAVEN_RELEASE_VERSION: release version (MAVEN_CURRENT_VERSION without qualifier)
#
function setReleaseVersion(){
	local pom_file=$1
	[ ! -f ${pom_file:=pom.xml} ] && error "'${1}' file doesn't exist."

	setMavenCurrentVersion $pom_file
	export MAVEN_RELEASE_VERSION=$(echo ${MAVEN_CURRENT_VERSION} | cut -d- -f1)
	echo "MAVEN_RELEASE_VERSION=${MAVEN_RELEASE_VERSION}"

	export MAVEN_RELEASE_VERSION_ARRAY=($(echo ${MAVEN_RELEASE_VERSION} | sed "s/\./ /g"))
	[ 3 -eq ${#MAVEN_RELEASE_VERSION_ARRAY[@]} ] || error "Split version doesn't contains 3 parts ${MAVEN_RELEASE_VERSION}."
}

#
# Check if given string starts with 'maintenance/'
#
function isMaintenanceBranch(){
	test "maintenance/" = "${1:0:12}"
	return $?
}

#
# Check if given string equals to 'master'
#
function isMasterBranch(){
	test "master" = "${1}"
	return $?
}

#
# Set GIT_BRANCH_COMMIT with last commit id of the given branch
# Return !=0 if branch is not found
#
function gitGiveLastCommitOfBranch(){
	local branch="$1"

	git fetch --all
	export GIT_BRANCH_COMMIT=$(git rev-parse --verify ${branch:=master} 2> /dev/null)
	test ! -z "${GIT_BRANCH_COMMIT}"
	return $?
}

#
# Create given branch
#
function gitCreateBranch(){
	echo "Try to create '$1' branch..."
	local branch="$1"
	[ -z "${branch}" ] && error "Given branch is empty."
	gitGiveLastCommitOfBranch "$branch" && error "The branch $branch already exists." 
	git checkout -b ${branch} || error "Can't checkout ${branch}."
	gitPushBranch "${branch}"
}

#
# Clean git local repository
#
function gitCleanLocal(){
	echo "Clean local git repository..."
	git reset --hard
	git clean -d -x -f
	git pull
}

#
# Push given branch
#
function gitPushBranch(){
	gitPush "--set-upstream origin "${1}""
}

#
# Git push to origin. Set DRY_RUN with any value to skip push.
#
function gitPush(){
	local push_cmd="git push -q ${1}"
	local echoed=""
	if [ ! -z "${DRY_RUN}" ]
	then
		echo "DRYN_RUN is set..."
		echoed="echo Skip command:"
	fi
	${echoed} ${push_cmd} || error "Can't push: ${push_cmd}"
}
