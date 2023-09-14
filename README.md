# Knative workflows via Apache Airflow

This fork of Apache Airflow executes DAGs similarly to the Kubernetes Executor
shipped with stock Apache Airflow.
However, instead of creating and deleting Kubernetes pods to execute tasks,
it uses Knative services.

These Knative services must be created ahead of time.
However, due to how Knative works, this does not mean that a worker pod is
running constantly.
Instead, Knative creates/scales/deletes the pods automatically as needed.
Moreover, instead of looking up task arguments in the database used by Airflow,
this fork directly sends them in the RPC to the Knative services
Likewise, the HTTP response by the Knative services includes the return value
of the task.

## Quick start guide
First, set up a cluster of one or more nodes with the `stock-only` configuration
as described in
[vHive Quickstart](https://github.com/vhive-serverless/vHive/blob/main/docs/quickstart_guide.md).
Do not start vHive, as it is not needed.
The relevant commands for a single-node cluster are reproduced here.

```bash
git clone --depth=1 https://github.com/vhive-serverless/vhive.git
cd vhive
mkdir -p /tmp/vhive-logs
./scripts/cloudlab/setup_node.sh stock-only  # this might print errors, ignore them
```

The `setup_node.sh` script might print some errors, don't worry about them and continue.

```bash
sudo screen -d -m containerd
./scripts/cluster/create_one_node_cluster.sh stock-only
cd ..
```

Install additional packages needed
```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo \
    "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo chmod 666 /var/run/docker.sock

sudo apt install python3-pip
pip install apache-airflow-client grpcio grpcio-tools

curl -sS https://webi.sh/k9s | sh
source ~/.config/envman/PATH.env
```

Now, the Kubernetes cluster and Knative should be ready.
It is time to deploy this fork of airflow with the following commands:
```bash
git clone --branch knative-worker https://github.com/vhive-serverless/airflow.git
cd airflow
./scripts/log_benchmark.sh
```
## Changing container registry
```
configs/values.yaml
scripts/update_images.sh
workflows/knative_yaml_builder/knative_service_template.yaml
```
Change container registry in files above to your prefered one.


## Deploying new workflows
A workflow (Apache Airflow also calls them DAGs) consists of the following files:
- A python file that defines the DAG using [Airflow Taskflow](https://airflow.apache.org/docs/apache-airflow/stable/core-concepts/taskflow.html).
- YAML files that define the Knative services for each function in the workflow.

Examples can be found in the [workflows](workflows) directory.
For instance, [xcom_dag.py](workflows/image/airflow-dags/xcpom_dag.py) contains
a workflow that pass current time value generated at producer function to consumer function.
The corresponding YAML files that define the Knative services for each
function in the workflow can be found in [workflows/knative_yams/xcom_dag](workflows/knative_yams/xcom_dag).

Since the DAGs are baked into the function and airflow images, it is a bit tedious
to deploy new DAGs.
However, the below step-by-step guide should make it easier.
1. Place your python workflow file in `workflows/image/airflow-dags`
2. Run `scripts/install_airflow.sh`. It will automatically clean up previous environment, rebuild knative worker yamls, and deploy airflow and knative workers with up to date DAGs.
3. Run `scripts/deploy_workflow.sh dag_id`, replacing `dag_id` with the id of your dag.
   Look in `workflows/knative_yamls` if you are not sure what the id of your dag is.
4. Execute your dag with
    ```bash
    python workflow-gateway/main.py
    ```
   Make sure to replace dag name and task name in the `main.py` to the ones you are triggering. 
   Also, check out [Airflow Python Client](https://github.com/apache/airflow-client-python) repository to add features that you might want for the python airflow client.

## Debugging
If you started a workflow, but it is crashing or does not terminate, you might
need to inspect the logs.
The most likely place to find useful information are the logs of Airflow's scheduler,
which can be accessed with [k9s](https://k9scli.io/) we installed while running above script.

If you need access to the logs of a function, you will need to find its pod id with kubectl -n airflow get pods. Then kubectl -n airflow logs <pod_id> user-container will give you the logs of the webserver that handles function invocations. To get the logs of the function execution, you can open a shell in the pod with
``` bash
kubectl -n airflow exec <pod_id> -- bash
```
and then navigate to the ./logs directory.

Airflow's web interface might also be helpful. Webserver is already exposed at http://localhost:8080. Log in with username admin and password admin.

## Logging
Running `./scripts/log_benchmark.sh` will reinstall entire Airflow with updated images, run a workflow, and store worker logs as text files in designated folder.
Or you can run script below to only get logs from worker directly.
```bash
log_dir=./benchmark/"$(date +%s)"
mkdir -p "$log_dir"
target="$(kubectl -n airflow get pods | grep "$target" | awk '{print $1}')"
kubectl -n airflow logs "$target" user-container > "$log_dir"/log_"$target".log
```