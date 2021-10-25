#! /bin/bash

echo "create-branch"
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

echo """
************************************************
* Create a maintenance/x.y branch from master. *
************************************************
"""

gitCleanLocal

[ -z ${BRANCH_NAME+x} ]  && error "BRANCH_NAME is not set."
setReleaseVersion

isMaintenanceBranch "${BRANCH_NAME}" && endScript "You are already on maintenance branch '${BRANCH_NAME}'."
isMasterBranch "${BRANCH_NAME}" || endScript "Unknown branch name '$BRANCH_NAME'."
isMasterBranch "${BRANCH_NAME}" && createMaintenanceBranch

endScript
