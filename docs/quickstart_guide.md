## Quick start guide

### Infrastructure Setup
First, we will set up a **single node** with vHive `stock-only` configuration.

To set up hardware infrastructure, refer to `CloudLab Deployment Notes` in
[vHive Quickstart](https://github.com/vhive-serverless/vHive/blob/main/docs/quickstart_guide.md#3-cloudlab-deployment-notes). You only need to rent 1-node.

To set up software infrastructure, clone this Airflow repository and run commands below. 

[setup_infrastructure.sh](../scripts/setup_infrastructure.sh) will setup Knative using vHive framework. For those who already have a working cluster can skip this script.

```bash
git clone --branch knative-worker https://github.com/vhive-serverless/airflow.git
./airflow/scripts/setup_infrastructure.sh
```

[setup_tools.sh](../scripts/setup_tools.sh) will install packages needed.
These aditional packages include: Docker, Airflow Python Client, gRPC Tools, and K9S

```bash
./airflow/scripts/setup_tools.sh
```

### Example Deployment

When `setup_infrastructure.sh` and `setup_tools.sh` are finished, run script below.

```bash
cd airflow
./scripts/quickstart_script.sh
```

[quickstart_script.sh](../scripts/quickstart_script.sh) deploys airflow using helm chart, and run a sample dag [avg_distributed.py](../workflows/image/airflow-dags/avg_distributed.py) twice to show cold start and warm start latency difference. The dag run trigger will return this result:

```bash
{'conf': {},
 'dag_id': 'compute_avg_distributed',
 'dag_run_id': 'manual_d686492b6be24f7e8974e79ca5d2e085',
 'data_interval_end': datetime.datetime(2023, 10, 9, 7, 40, 21, 781845, tzinfo=tzutc()),
 'data_interval_start': datetime.datetime(2023, 10, 9, 7, 40, 21, 781845, tzinfo=tzutc()),
 'end_date': None,
 'execution_date': datetime.datetime(2023, 10, 9, 7, 40, 21, 781845, tzinfo=tzutc()),
 'external_trigger': True,
 'last_scheduling_decision': None,
 'logical_date': datetime.datetime(2023, 10, 9, 7, 40, 21, 781845, tzinfo=tzutc()),
 'note': None,
 'run_type': 'manual',
 'start_date': None,
 'state': 'queued'}
```

And after a few seconds, result will be pulled from Database. 
```bash
producer: {'dag_id': 'compute_avg_distributed',
 'execution_date': '2023-10-09T07:40:21.781845+00:00',
 'key': 'return_value',
 'map_index': -1,
 'task_id': 'extract',
 'timestamp': '2023-10-09T07:40:31.530512+00:00',
 'value': '[1, 2, 3, 4]'}

consumer: {'dag_id': 'compute_avg_distributed',
 'execution_date': '2023-10-09T07:40:21.781845+00:00',
 'key': 'return_value',
 'map_index': -1,
 'task_id': 'do_avg',
 'timestamp': '2023-10-09T07:41:07.570061+00:00',
 'value': '2.5'}

End-to-end Latency:
trigger_time: 0.43595568499949877
execution_and_retrieve_time: 46.40222336900024
```

`trigger_time` and `execution_and_retrieve_time` for each task is measured with Airflow-webserver HTTP response time. 


```bash
[2023-10-09T07:41:07.724+0000] {kubernetes_executor_utils.py:421} INFO - TIMING: {"function": "worker_execution", "times": [3.0325508979994993], "timestamp_annotations": {"dag_id": "compute_avg_distributed", "task_id": "do_avg", "try_number": 1, "run_id": "manual_d686492b6be24f7e8974e79ca5d2e085", "map_index": -1}}
```
---
For warm start, same result will be returned with much shorter execution time and latency

```bash
End-to-end Latency:
trigger_time: 0.3572731180001938
execution_and_retrieve_time: 4.175672332999966
```

```bash
[2023-10-09T07:41:16.004+0000] {kubernetes_executor_utils.py:421} INFO - TIMING: {"function": "worker_execution", "times": [0.5604807079998864], "timestamp_annotations": {"dag_id": "compute_avg_distributed", "task_id": "do_avg", "try_number": 1, "run_id": "manual_054326cf5be74c839670338674d40569", "map_index": -1}}
```

You can retrieve per-task execution time by viewing the log of scheduler pod using `k9s`
Also the quickstart script will automatically dump pods logs in benchmark folder.