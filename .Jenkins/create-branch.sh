#! /bin/bash

base_dir=$(dirname $0)
source ${base_dir}/jenkins-functions.sh

#
# Branch maintenance name will be maintenance/x.y
#
function setReleaseBranchName(){
	local splitVers=(${MAVEN_RELEASE_VERSION//./ })
	[ 3 -eq ${#splitVers[@]} ] || error "Version must follow x.y.z pattern: ${MAVEN_RELEASE_VERSION}."
	export RELEASE_BRANCH_NAME="maintenance/${splitVers[0]}.${splitVers[1]}"
	echo "RELEASE_BRANCH_NAME=${RELEASE_BRANCH_NAME}"
}

function createMaintenanceBranch(){
	setReleaseBranchName
	gitCreateBranch "$RELEASE_BRANCH_NAME"
}

function updateMasterVersion(){
	MAVEN_RELEASE_VERSION_ARRAY=($(splitReleaseVersion))

	local minor=$((${MAVEN_RELEASE_VERSION_ARRAY[1]}+1))
	export NEW_MASTER_VERSION="${MAVEN_RELEASE_VERSION_ARRAY[0]}.${minor}.${MAVEN_RELEASE_VERSION_ARRAY[2]}-SNAPSHOT"

	export TEMP_BUMP_BRANCH="temp/bump/${NEW_MASTER_VERSION}"
	git checkout -b "${TEMP_BUMP_BRANCH}"
	mvnUpdateVersion "${NEW_MASTER_VERSION}"
	git add .
	git commit -m "chore: bump ${MAVEN_CURRENT_VERSION} version to ${NEW_MASTER_VERSION}"
	gitPushBranch "${TEMP_BUMP_BRANCH}"
}

function jenkinsMessage(){
	echo """
- ${RELEASE_BRANCH_NAME} branch has been created from ${BRANCH_NAME}
- ${TEMP_BUMP_BRANCH} branch has been created and version has been bumped to ${NEW_MASTER_VERSION}

Please, create PR and continue after merge:
${GIT_REPOSITORY}/compare/${BRANCH_NAME}...${TEMP_BUMP_BRANCH}?expand=1
""" >> ${JENKINS_OUT_FILE}
}


head "Create a maintenance/x.y branch from master."

gitCleanLocal 
setGitRepository 
setBranchName 

setReleaseVersion

isMaintenanceBranch "${BRANCH_NAME}" && error "You are already on maintenance branch '${BRANCH_NAME}'."
isMasterBranch "${BRANCH_NAME}" || error "You are not on master branch but on '$BRANCH_NAME'."

createMaintenanceBranch 
gitCleanLocal 
git checkout ${BRANCH_NAME}  # come back to master
updateMasterVersion 
jenkinsMessage

endScript
