#!/bin/bash

# Specifies the repository the runs are executed against
repository=$GITHUB_REPOSITORY
# Specifies the workflow to search runs from
workflow=$GITHUB_WORKFLOW
workflow_names=$WORKFLOW_NAMES
# Specifies the event name (pull_request, push, merge_group)
event=$GITHUB_EVENT_NAME
# Specifies the current run id we don't want to touch
current_run_id=$GITHUB_RUN_ID
# Get current run `createdAt`
current_run_created_at=$(gh run view $current_run_id --repo $repository --json createdAt --jq '.[]')

# Define the list of workflows for jq
if [ -z "$workflow_names" ]; then
  workflow_names=$workflow
fi

IFS=',' read -ra arr <<< "$workflow_names"
for w in "${arr[@]}"; do
  if [ -n "$workflows_jq_selector" ]; then
    or=" or "
  fi
  workflows_jq_selector+=$or'.workflowName == "'$w'"'
done

# Prints
echo "repository:               $repository"
echo "workflows:                $workflow_names"
echo "workflows_jq_selector:    $workflows_jq_selector"
echo "event:                    $event"
echo "current_run_id:           $current_run_id"
echo "current_run_created_at:   $current_run_created_at"

if [ "$event" == "merge_group" ]; then
  ###########################
  ## event: merge_group
  ###########################
  # Specifies the ref branch which is the temporary branch created by Gh and formatted such as `gh-readonly-queue/main/pr-{num}-{sha}`
  ref=$GITHUB_REF
  # extract pr identifier formatted as `pr-{pr}`
  pr_identifier=$(echo $ref | grep -oP 'pr-\d+')
  
  echo "ref:                      $ref"
  echo "pr_identifier:            $pr_identifier"

  # Returns the list of runs which respect all the following conditions:
  #   - event is merge_group
  #   - worflow is among the ones specified
  #   - the run is related to the same pr number than the current run
  #   - the run is in progress or queued
  #   - the run is NOT the current one
  #   - the run is created before the current one
  runs=$(gh run list --repo $repository -L 200 \
    --json databaseId,workflowName,createdAt,event,status,number,headBranch  \
    --jq 'map(select(.headBranch | contains("'${pr_identifier}'"))
          | select('"${workflows_jq_selector}"')
          | select(.event == "'${event}'")
          | select(.status == "in_progress" or .status == "queued")
          | select(.databaseId != '"${current_run_id}"')
          | select(.createdAt < "'${current_run_created_at}'"))')

elif [ "$event" == "pull_request" ] || [ "$event" == "push" ]; then
  ###########################
  ## event: pull_request / push
  ###########################

  # Specifies the ref branch which is the temporary branch created by Gh and formatted such as `gh-readonly-queue/main/pr-{num}-{sha}`
  if [ "$event" == "pull_request" ]; then
    ref=$GITHUB_HEAD_REF
  elif [ "$event" == "push" ]; then
    ref=$GITHUB_REF_NAME
  fi

  # Prints
  echo "ref:                      $ref"

  # Returns the list of runs which respect all the following conditions:
  #   - event is pull_request / push
  #   - worflow is among the ones specified
  #   - the run is related to the same ref than the current run
  #   - the run is in progress or queued
  #   - the run is NOT the current one
  #   - the run is created before the current one
  runs=$(gh run list --repo $repository -L 200 \
    --json databaseId,workflowName,createdAt,event,status,number,headBranch \
    --jq 'map(select(.headBranch == "'${ref}'")
          | select('"${workflows_jq_selector}"')
          | select(.event == "'${event}'")
          | select(.status == "in_progress" or .status == "queued")
          | select(.databaseId != '"${current_run_id}"')
          | select(.createdAt < "'${current_run_created_at}'"))')
fi

echo "Runs for cancellation: $runs"

# Get run ids
run_ids=$(echo $runs | jq -c '[ .[] | .databaseId ]')
echo "runs ids for cancellation: $run_ids"

# Cancels the run
echo $run_ids | jq '.[]' | xargs -I{} bash -c "echo 'Cancelling run {}...' && gh run cancel --repo $repository {} || true"