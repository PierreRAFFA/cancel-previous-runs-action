# Cancel Previous Runs Action 

This GitHub action is responsible to cancel any previous runs for the current workflow.
It supports 3 events:  
- pull_request  
- push  
- merge_group  

#### For `merge_group` event:
The cancellation of the previous runs could be required when:
- the merge queue has entries running concurrently  
- the first entry fails and all the next ones will have to run again  
This result in multiple runs executed for the same PR queued.  

## Requirements
- gh (comes natively with Github-hosted runners) + write permissions to setup in the repo settings
- jq

## Usage 

Place this job at the beginning of your workflow.  
Once the job running, it will check for all runs related to the same context than the current run and cancel all of them.  

```yaml
jobs:
  cancel-previous-runs:
    runs-on: ubuntu-latest
    steps:
      - name: Cancel Previous Runs
        uses: pierreraffa/cancel-previous-runs-action
```