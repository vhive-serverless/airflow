FROM apache/airflow:2.7.0
STOPSIGNAL SIGINT
RUN pip install grpcio grpcio-tools
COPY airflow-dags /opt/airflow/dags
COPY airflow /home/airflow/.local/lib/python3.8/site-packages/airflow
# COPY flask_worker_entrypoint.py /opt/airflow/flask_worker_entrypoint.py
# ENTRYPOINT ["flask", "--app", "/opt/airflow/flask_worker_entrypoint.py", "run", "--host", "0.0.0.0", "--port", "50000"]
EXPOSE 50000
ENTRYPOINT ["python", "/home/airflow/.local/lib/python3.8/site-packages/airflow/grpc/remote_xcom/grpc_worker_entrypoint.py", "--port", "50000"]
