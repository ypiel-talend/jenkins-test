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
	local newVersion="${MAVEN_RELEASE_VERSION_ARRAY[0]}.${minor}.${MAVEN_RELEASE_VERSION_ARRAY[2]}-SNAPSHOT"

	local temp_branch="temp/bump/${newVersion}"
	git checkout -b "${temp_branch}"
	mvnUpdateVersion "${newVersion}"
	git add .
	git commit -m "chore: bump ${MAVEN_CURRENT_VERSION} version to ${newVersion}"
	pushBranch "${branch}"
	mergeBranches
}

echo """
************************************************
* Create a maintenance/x.y branch from master. *
************************************************
"""

gitCleanLocal
setBranchName
setReleaseVersion

isMaintenanceBranch "${BRANCH_NAME}" && endScript "You are already on maintenance branch '${BRANCH_NAME}'."
isMasterBranch "${BRANCH_NAME}" || endScript "Unknown branch name '$BRANCH_NAME'."
#isMasterBranch "${BRANCH_NAME}" && createMaintenanceBranch

createMaintenanceBranch
git checkout ${BRANCH_NAME} # come back to master
updateMasterVersion

endScript
