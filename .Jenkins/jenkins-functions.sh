# set a value in DEBUG variable to echo all commands
[ ! -z ${DEBUG+x} ] && set -x

function error(){
	echo "Execution error:" 1>&2
	echo ${1:=No error message} 1>&2
	exit 2
}

#
# Set:
# MAVEN_CURRENT_VERSION: version from the pom
#
function setMavenCurrentVersion(){
	local pom_file=$1
	[ ! -f ${pom_file:=pom.xml} ] && error "'${1}' file doesn't exist."
	export MAVEN_CURRENT_VERSION=$(mvn org.apache.maven.plugins:maven-help-plugin:3.2.0:evaluate -Dexpression=project.version -q -DforceStdout)
	echo "MAVEN_CURRENT_VERSION=${MAVEN_CURRENT_VERSION}"
}

#
# Set:
# MAVEN_CURRENT_VERSION: version from the pom
# MAVEN_RELEASE_VERSION: release version (MAVEN_CURRENT_VERSION without qualifier)
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
