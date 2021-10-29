# set a value in DEBUG variable to echo all commands
[ ! -z ${DEBUG+x} ] && set -x

# Define a temporary output file
export JENKINS_OUT_FILE=$(mktemp)
export LOG_FILE=$(mktemp)

function error(){
	echo "Display log file:" >&2
	cat ${LOG_FILE} >&2
	echo "end log file." >&2
	echo >&2
	echo "Execution error:" 1>&2
	echo ${1:=No error message} 1>&2
	exit 2
}

function endScript(){
	local msg=$1

	cat ${JENKINS_OUT_FILE}

	[ ! -z "${msg}" ] && echo "${msg}"
	exit 0
}

function head(){
	echo """
************************************************
* ${1}
************************************************
""" | tee ${LOG_FILE} | tee ${JENKINS_OUT_FILE}
}

#
# Set BRANCH_NAME, can be set by Jenkins, if not retrieve with git.
#
function setBranchName(){
	[ -z ${BRANCH_NAME+x} ] && echo "BRANCH_NAME not set, retrieved from git..." && export BRANCH_NAME=$(git branch --show-current)
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
	pushBranch "${branch}"
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

function gitPush(){
	local push_cmd="git push -q ${1}"
	if [ -z ${DRY_RUN+x} ];
	then
		echo "DRYN_RUN is set..."
		push_cmd="echo "skip git push command: $push_cmd""
	fi
	${push_cmd} || error "Can't push: ${push_cmd}"
}
