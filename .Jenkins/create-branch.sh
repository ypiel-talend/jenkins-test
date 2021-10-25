#! /bin/bash

echo "create-branch"
branch_version=$(mvn org.apache.maven.plugins:maven-help-plugin:3.2.0:evaluate -Dexpression=project.version -q -DforceStdout)
release_version=$(echo ${pre_release_version} | cut -d- -f1)

echo "branch_version: ${branch_version}"
echo "release_version: ${release_version}"
echo "branch-name: ${BRANCH_NAME}"
