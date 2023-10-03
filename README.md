# redfly-ycsb
Script to run ycsb benchmarks, through periodic cron job
## Dependencies
- sed
- sar
- perf-tools/cachestat
- bcc-tools/syscount

## Usage
```bash
$ start.sh (server type - r/d) (workload type- a/b/c/d) {recordcount operationcount} optional 
```

Note:-
- It assumes that YCSB is unpacked at /mnt/io_uring
- Ensure that the user executing the script has appropriate permissions for /mnt/io_uring
- results are stored in /mnt/io_uring/results. Each invocation of the script creates a folder
  in the results folder, with name as "count-date", where count is the count of how many times 
  the script has run. Though it does **NOT** take into account the failed/unsuccessful/killed invocations