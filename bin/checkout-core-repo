#!/usr/bin/env bash

# Default to the main branch if we don't find a matching branch on the starter repository.
CORE_REPO_BRANCH="main"

# Look for a matching branch on the starter repository when running tests in CI
CI_BRANCH=$TARGET_BRANCH
echo "Looking for branch ${TARGET_BRANCH}"
if [[ -v CI_BRANCH ]]
then
  BRANCH_RESPONSE=$(curl https://api.github.com/repos/bullet-train-co/bullet_train-core/branches/$CI_BRANCH)

  echo "Branch response ===================="
  echo $BRANCH_RESPONSE

  # If the branch is missing in the repo the response will not contain the branch name
  if echo $BRANCH_RESPONSE | grep "$TARGET_BRANCH"; then
    CORE_REPO_BRANCH=$CI_BRANCH
  fi
fi

echo "Cloning from ${CORE_REPO_BRANCH}..."
git clone -b $CORE_REPO_BRANCH --depth 1 https://github.com/bullet-train-co/bullet_train-core.git .

ls -al
