#! /bin/bash

echo "create-branch"
base_dir=$(dirname $0)
source ${base_dir}/jenkins-functions.sh

[ -z ${BRANCH_NAME+x} ]  && error "BRANCH_NAME is not set"

setReleaseVersion pom.xml

echo "maven_version: ${MAVEN_CURRENT_VERSION}"
echo "release_version: ${MAVEN_RELEASE_VERSION}"
echo "branch-name: ${BRANCH_NAME}"

isMaintenanceBranch "${BRANCH_NAME}" && echo "yes maintenance"
isMasterBranch "${BRANCH_NAME}" && echo "yes master"
