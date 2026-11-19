#!/bin/bash
set -euo pipefail

# This script is executed by the official Postgres image only when its data
# directory is initialized for the first time.
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname postgres \
  -v app_user="$APP_DB_USER" -v app_password="$APP_DB_PASSWORD" \
  -v airflow_user="$AIRFLOW_DB_USER" -v airflow_password="$AIRFLOW_DB_PASSWORD" <<'SQL'
SELECT format('CREATE ROLE %I LOGIN PASSWORD %L', :'app_user', :'app_password')
WHERE NOT EXISTS (SELECT FROM pg_roles WHERE rolname = :'app_user') \gexec
SELECT format('CREATE ROLE %I LOGIN PASSWORD %L', :'airflow_user', :'airflow_password')
WHERE NOT EXISTS (SELECT FROM pg_roles WHERE rolname = :'airflow_user') \gexec
SELECT format('CREATE DATABASE %I OWNER %I', 'flights_dw', :'app_user')
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'flights_dw') \gexec
SELECT format('CREATE DATABASE %I OWNER %I', 'airflow', :'airflow_user')
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'airflow') \gexec
SQL
