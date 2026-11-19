from __future__ import annotations
from datetime import datetime, timedelta
import sys
sys.path.insert(0, "/opt/airflow")

from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.postgres.operators.postgres import PostgresOperator
from src.load_raw import extract_and_load
from src.transform import transform_raw

def run_transform(**context):
    raw_id = context["ti"].xcom_pull(task_ids="extract_load_raw")
    if raw_id is None:
        raise ValueError("Extraction task did not return a raw_id")
    transform_raw(int(raw_id))

with DAG(
    dag_id="opensky_flight_elt",
    description="OpenSky REST API to PostgreSQL raw, staging and warehouse layers",
    template_searchpath=["/opt/airflow"],
    start_date=datetime(2025, 1, 1),
    schedule="0 * * * *",
    catchup=False,
    max_active_runs=1,
    default_args={
        "owner": "data-engineering-intern",
        "depends_on_past": False,
        "retries": 2,
        "retry_delay": timedelta(minutes=2),
    },
    tags=["opensky", "week1", "week2", "elt"],
) as dag:
    initialize_database = PostgresOperator(
        task_id="initialize_database_objects",
        postgres_conn_id="flights_postgres",
        sql="sql/00_init.sql",
    )
    extract_load_raw = PythonOperator(
        task_id="extract_load_raw",
        python_callable=extract_and_load,
    )
    transform_to_warehouse = PythonOperator(
        task_id="transform_to_warehouse",
        python_callable=run_transform,
    )
    initialize_database >> extract_load_raw >> transform_to_warehouse
