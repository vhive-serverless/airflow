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

When `setup_infrastructure.sh` is finished, run script below.

```bash
cd airflow
./scripts/quickstart_script.sh
```

[quickstart_script.sh](../scripts/quickstart_script.sh) deploys airflow using helm chart, and run a sample dag [avg_distributed.py](../workflows/image/airflow-dags/avg_distributed.py). The dag run trigger will return this result:

```bash
{'conf': {},
 'dag_id': 'compute_avg_distributed',
 'dag_run_id': 'manual_0eec7686d66e49e5ba5bdc92c821e49f',
 'data_interval_end': datetime.datetime(2023, 9, 15, 17, 8, 30, 915336, tzinfo=tzutc()),
 'data_interval_start': datetime.datetime(2023, 9, 15, 17, 8, 30, 915336, tzinfo=tzutc()),
 'end_date': None,
 'execution_date': datetime.datetime(2023, 9, 15, 17, 8, 30, 915336, tzinfo=tzutc()),
 'external_trigger': True,
 'last_scheduling_decision': None,
 'logical_date': datetime.datetime(2023, 9, 15, 17, 8, 30, 915336, tzinfo=tzutc()),
 'note': None,
 'run_type': 'manual',
 'start_date': None,
 'state': 'queued'}
```

And after a few seconds, result will be pulled from Database. 
```bash
producer: {'dag_id': 'compute_avg_distributed',
 'execution_date': '2023-09-15T17:08:30.915336+00:00',
 'key': 'return_value',
 'map_index': -1,
 'task_id': 'extract',
 'timestamp': '2023-09-15T17:08:31.827119+00:00',
 'value': '[1, 2, 3, 4]'}

consumer: {'dag_id': 'compute_avg_distributed',
 'execution_date': '2023-09-15T17:08:30.915336+00:00',
 'key': 'return_value',
 'map_index': -1,
 'task_id': 'do_avg',
 'timestamp': '2023-09-15T17:08:33.685496+00:00',
 'value': '2.5'}

trigger_time: 0.23874281800090102
execution_and_retrieve_time: 3.1310619869982474
```

`trigger_time` and `execution_and_retrieve` returned is measured with Airflow-webserver HTTP response time. 


```bash
scheduler{kubernetes_executor_utils.py:412} INFO - execution_timing: {'execution_time': 0.34931873599998653}                                                                                               
scheduler{kubernetes_executor_utils.py:420} INFO - Task run {'dag_id': 'compute_avg_distributed', 'task_id': 'do_avg', 'try_number': 1, 'run_id': 'manual_0eec7686d66e49e5ba5bdc92c821e49f', 'map_index': -1} done with status code 200
```

You can retrieve per-task execution time by viewing the log of scheduler pod using `k9s`
Also the quickstart script will automatically dump pods logs in benchmark folder.