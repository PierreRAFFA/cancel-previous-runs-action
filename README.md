# Cancel Previous Runs Action 

This GitHub action is responsible to cancel any previous runs for the current workflow.  
It supports 3 events:  
- pull_request  
- push  
- merge_group  

## Requirements
- gh (comes natively with Github-hosted runners) + write permissions to setup in the repo settings
- jq

## Event Handlers

For `pull_request` and `push` events, the cancellation is performed for previous runs:  
- which are `in_progress` state
- from the same workflow
- from the same branch
- older than the current run

For `merge_group` event, the cancellation is performed for previous runs:  
- which are `in_progress` state
- from the same workflow
- related the same PR 
- older than the current run

The cancellation of the previous runs could be required when:
- the merge queue has entries running concurrently  
- the first entry fails and all the next ones will have to run again  
This result in multiple runs executed for the same queued PR.  

## Usage 
Place this job at the beginning of your workflow.  
Once the job running, it will check for all runs related to the same context than the current run and cancel all of them.  

```yaml
jobs:
  cancel-previous-runs:
    runs-on: ubuntu-latest
    steps:
      - name: Cancel Previous Runs
        uses: pierreraffa/cancel-previous-runs-action@1.1
```