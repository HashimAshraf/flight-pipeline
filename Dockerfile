FROM apache/airflow:2.10.5-python3.11
USER airflow
RUN pip install --no-cache-dir \
    apache-airflow-providers-postgres==5.14.0 \
    requests==2.32.3 \
    sqlparse==0.5.3
