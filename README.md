# Cancel Previous Runs Action 
#### (merge_group event only at the moment)

This GitHub action is responsible to cancel any previous runs for the current workflow that are:  
- triggered by `merge_group` event  
- related to the same PR number than the current run  
- `in_progress` status.  

The cancellation of the previous runs could be required when:
- the merge queue has entries running concurrently  
- the first entry fails and all the next ones will have to run again  
This result in multiple runs executed for the same PR queued.  


## Usage

Place this job at the beginning of your workflow.  
Once the job running, it will check for all runs related to the same PR than the current run and cancel all of them.  

```yaml
jobs:
  cancel-previous-runs:
    runs-on: ubuntu-latest
    if: github.event_name == 'merge_group'
    steps:
      - name: Cancel Previous Runs
        uses: pierreraffa/cancel-previous-runs-action
```