#!/usr/bin/env bash

set -e

echo "The REPOSITORY = $REPOSITORY"
echo "The TARGET_BRANCH= $TARGET_BRANCH"
echo "The DEFAULT_BRANCH= $DEFAULT_BRANCH"

# Default to the main branch if we don't find a matching branch on the starter repository.
REPO_BRANCH=$DEFAULT_BRANCH

# Look for a matching branch on the starter repository when running tests in CI
CI_BRANCH=$TARGET_BRANCH
echo "Looking for branch ${TARGET_BRANCH}"
if [[ -v CI_BRANCH ]]
then
  BRANCH_RESPONSE=$(curl https://api.github.com/repos/$REPOSITORY/branches/$CI_BRANCH)

  echo "Branch response ===================="
  echo $BRANCH_RESPONSE

  # If the branch is missing in the repo the response will not contain the branch name
  if echo $BRANCH_RESPONSE | grep "$TARGET_BRANCH"; then
    REPO_BRANCH=$CI_BRANCH
  fi
fi

echo "Using branch: ${REPO_BRANCH}"

echo "BRANCH_TO_CHECKOUT=${REPO_BRANCH}" >> "$GITHUB_OUTPUT"
