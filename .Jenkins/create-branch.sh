#! /bin/bash

echo "create-branch"
echo "A NEW BRANCH !!!!!!!!!!!"
branch_version=$(mvn org.apache.maven.plugins:maven-help-plugin:3.2.0:evaluate -Dexpression=project.version -q -DforceStdout)
release_version=$(echo ${branch_version} | cut -d- -f1)
branch_name=${BRANCH_NAME:=$(git rev-parse --abbrev-ref HEAD)} # if BRANCH_NAME is not set, retrieve branch name

echo "branch_version: ${branch_version}"
echo "release_version: ${release_version}"
echo "branch-name: ${branch_name}"
