# set a value in DEBUG variable to echo all commands
[ ! -z ${DEBUG+x} ] && set -x

function error(){
	echo "Execution error:" 1>&2
	echo ${1:=No error message} 1>&2
	exit 2
}

function endScript(){
	local msg=$1
	[ ! -z "${msg}" ] && echo "${msg}"
	echo "That's all folks!"
	exit 0
}

#
# Set BRANCH_NAME, can be set by Jenkins, if not retrieve with git.
#
function setBranchName(){
	[ -z ${BRANCH_NAME+x} ] && echo "BRANCH_NAME not set, retrieved from git..." && export BRANCH_NAME=$(git branch --show-current)
	echo "BRANCH_NAME=${BRANCH_NAME}" 
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
# Set MAVEN_RELEASE_VERSION: release version (MAVEN_CURRENT_VERSION without qualifier)
#
function setReleaseVersion(){
	local pom_file=$1
	[ ! -f ${pom_file:=pom.xml} ] && error "'${1}' file doesn't exist."

	setMavenCurrentVersion $pom_file
	export MAVEN_RELEASE_VERSION=$(echo ${MAVEN_CURRENT_VERSION} | cut -d- -f1)
	echo "MAVEN_RELEASE_VERSION=${MAVEN_RELEASE_VERSION}"
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
	git checkout -b ${branch}
	git push --set-upstream origin ${branch}
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
