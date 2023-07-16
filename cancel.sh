#!/bin/bash

# Specifies the workflow to search runs from
workflow=$GITHUB_WORKFLOW
# Specifies the event name (pull_request, push, merge_group)
event=$GITHUB_EVENT_NAME
# Specifies the current run id we don't want to touch
current_run_id=$GITHUB_RUN_ID

###########################
## event: merge_group
###########################
if [ "$event" = "merge_group" ]; then
  # Specifies the ref branch which is the temporary branch created by Gh and formatted such as `gh-readonly-queue/main/pr-{num}-{sha}`
  ref=$GITHUB_REF
  # extract pr identifier formatted as `pr-{pr}`
  pr_identifier=$(echo $ref | grep -oP 'pr-\d+')
  # Get current run `createdAt`
  current_run_created_at=$(gh run view $current_run_id --json createdAt --jq '.[]')

  # Prints
  echo "workflow:                 $workflow"
  echo "ref:                      $ref"
  echo "current_run_id:           $current_run_id"
  echo "pr_identifier:            $pr_identifier"
  echo "current_run_created_at:   $current_run_created_at"

  # Returns the list of runs which respect all the following conditions:
  #   - event is merge_group
  #   - worflow is the one specified
  #   - the run is related to the same pr number than the current run
  #   - the run is in progress
  #   - the run is NOT the current one
  #   - the run is created before the current one
  runs=$(gh run list -e merge_group --workflow $workflow -L 200 \
    --json databaseId,workflowName,createdAt,status,number,headBranch  \
    --jq 'map(select(.headBranch | contains("'${pr_identifier}'"))
          | select(.status == "completed")
          | select(.databaseId != '"${current_run_id}"')
          | select(.createdAt < "'${current_run_created_at}'"))')
  echo "runs for cancellation: $runs"

  # Get run ids
  run_ids=$(echo $runs | jq -c '[ .[] | .databaseId ]')
  echo "runs ids for cancellation: $run_ids"

  # Cancels the run
  echo $run_ids | jq '.[]' | xargs -I{} bash -c "echo 'Cancelling run {}...' && gh run cancel {}"
else
###########################
## event: pull_request/push
###########################
  # Specifies the ref branch which is the temporary branch created by Gh and formatted such as `gh-readonly-queue/main/pr-{num}-{sha}`
  ref=$GITHUB_REF
  echo "GITHUB_SHA: ${GITHUB_SHA}"
  echo "GITHUB_REF: ${GITHUB_REF}"
  echo "GITHUB_HEAD_REF: ${GITHUB_HEAD_REF}"
fi