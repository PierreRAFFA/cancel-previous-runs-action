#!/bin/bash

# Specifies the workflow to search runs from
workflow=$GITHUB_WORKFLOW
# Specifies the event name (pull_request, push, merge_group)
event=$GITHUB_EVENT_NAME
# Specifies the current run id we don't want to touch
current_run_id=$GITHUB_RUN_ID
# Get current run `createdAt`
current_run_created_at=$(gh run view $current_run_id --json createdAt --jq '.[]')

if [ "$event" = "merge_group" ]; then
  ###########################
  ## event: merge_group
  ###########################
  # Specifies the ref branch which is the temporary branch created by Gh and formatted such as `gh-readonly-queue/main/pr-{num}-{sha}`
  ref=$GITHUB_REF
  # extract pr identifier formatted as `pr-{pr}`
  pr_identifier=$(echo $ref | grep -oP 'pr-\d+')
  

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
  runs=$(gh run list --workflow $workflow -L 200 \
    --json databaseId,workflowName,createdAt,event,status,number,headBranch  \
    --jq 'map(select(.headBranch | contains("'${pr_identifier}'"))
          | select(.event == "'${event}'")
          | select(.status == "in_progress")
          | select(.databaseId != '"${current_run_id}"')
          | select(.createdAt < "'${current_run_created_at}'"))')

elif [ "$event" = "pull_request" ]; then
  ###########################
  ## event: pull_request
  ###########################
  # Specifies the ref branch which is the temporary branch created by Gh and formatted such as `gh-readonly-queue/main/pr-{num}-{sha}`
  ref=$GITHUB_HEAD_REF

  # Prints
  echo "workflow:                 $workflow"
  echo "ref:                      $ref"
  echo "current_run_id:           $current_run_id"
  echo "current_run_created_at:   $current_run_created_at"
  printenv | grep GITHUB 

  # Returns the list of runs which respect all the following conditions:
  #   - event is merge_group
  #   - worflow is the one specified
  #   - the run is related to the same pr number than the current run
  #   - the run is in progress
  #   - the run is NOT the current one
  #   - the run is created before the current one
  runs=$(gh run list --workflow $workflow -L 200 \
    --json databaseId,workflowName,createdAt,event,status,number,headBranch \
    --jq 'map(select(.headBranch == "'${ref}'")
          | select(.event == "'${event}'")
          | select(.status == "in_progress")
          | select(.databaseId != '"${current_run_id}"')
          | select(.createdAt < "'${current_run_created_at}'"))')

elif [ "$event" = "push" ]; then
  ###########################
  ## event: push
  ###########################
  printenv | grep GITHUB
fi

echo "Runs for cancellation: $runs"

# Get run ids
run_ids=$(echo $runs | jq -c '[ .[] | .databaseId ]')
echo "runs ids for cancellation: $run_ids"

# Cancels the run
echo $run_ids | jq '.[]' | xargs -I{} bash -c "echo 'Cancelling run {}...' && gh run cancel {} || true"