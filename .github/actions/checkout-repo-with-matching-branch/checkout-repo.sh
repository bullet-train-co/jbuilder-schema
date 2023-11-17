#!/usr/bin/env bash

set -e

echo "The TARGET_DIR = $TARGET_DIR"
echo "The TARGET_REPO = $TARGET_REPO"

STARTING_DIR=$pwd
cd $TARGET_DIR

# Default to the main branch if we don't find a matching branch on the starter repository.
REPO_BRANCH="main"

# Look for a matching branch on the starter repository when running tests in CI
CI_BRANCH=$TARGET_BRANCH
echo "Looking for branch ${TARGET_BRANCH}"
if [[ -v CI_BRANCH ]]
then
  BRANCH_RESPONSE=$(curl https://api.github.com/repos/$TARGET_REPO/branches/$CI_BRANCH)

  echo "Branch response ===================="
  echo $BRANCH_RESPONSE

  # If the branch is missing in the repo the response will not contain the branch name
  if echo $BRANCH_RESPONSE | grep "$TARGET_BRANCH"; then
    REPO_BRANCH=$CI_BRANCH
  fi
fi

echo "Cloning from ${REPO_BRANCH}..."
git clone -b $REPO_BRANCH --depth 1 https://github.com/$TARGET_REPO.git .

ls -al

cd $STARTING_DIR
