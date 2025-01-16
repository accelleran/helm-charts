# Block Merging

This action checks whether all checks have successfully completed before allowing a merge.

## Prerequisites

Configure branch protection rules for the main branch:

* Enable "Require status checks to pass before merging"
* Enable "Require branches to be up to date before merging"

## Bypassing

The mergeability check can be bypassed by using the prefix `fix(mergeability): ` in the PR title.
