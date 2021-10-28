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
	local minor=$((${MAVEN_RELEASE_VERSION_ARRAY[1]}+1))
	export NEW_MASTER_VERSION="${MAVEN_RELEASE_VERSION_ARRAY[0]}.${minor}.${MAVEN_RELEASE_VERSION_ARRAY[2]}-SNAPSHOT"

	local temp_branch="temp/bump/${NEW_MASTER_VERSION}"
	git checkout -b "${temp_branch}"
	mvnUpdateVersion "${NEW_MASTER_VERSION}"
	git add .
	git commit -m "chore: bump ${MAVEN_CURRENT_VERSION} version to ${NEW_MASTER_VERSION}"
	pushBranch "${temp_branch}"
}

function jenkinsMessage(){
	echo """
- ${RELEASE_BRANCH_NAME} has been created from ${BRANCH_NAME}
- ${temp_branch} has been create and version has been bumped to ${NEW_MASTER_VERSION}

Please, create PR and continue after merge:
${GIT_REPOSITORY}/compare/${BRANCH_NAME}...${temp_branch}?expand=1
""" >> ${TEMP_FILE}
}


echo """
************************************************
* Create a maintenance/x.y branch from master. *
************************************************
"""

gitCleanLocal > ${LOG_FILE}
setGitRepository > ${LOG_FILE}
setBranchName > ${LOG_FILE}
setReleaseVersion > ${LOG_FILE}

isMaintenanceBranch "${BRANCH_NAME}" && error "You are already on maintenance branch '${BRANCH_NAME}'."
isMasterBranch "${BRANCH_NAME}" || error "Unknown branch name '$BRANCH_NAME'."

createMaintenanceBranch > ${LOG_FILE}
git checkout ${BRANCH_NAME} > ${LOG_FILE} # come back to master
updateMasterVersion > ${LOG_FILE}
jenkinsMessage

endScript
