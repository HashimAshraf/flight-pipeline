# Week 2 Troubleshooting Reference

Use the commands below to diagnose problems from evidence rather than guessing. Add a
dated entry to the incident log only after reproducing an issue; do not claim that a
possible failure happened if it did not.

| Symptom | Diagnostic | Likely cause | Resolution |
|---|---|---|---|
| DAG missing from Airflow | `docker compose exec airflow-scheduler airflow dags list-import-errors` | Python import error or DAG file not mounted | Check scheduler logs, `dags/` mount and Python imports |
| `ModuleNotFoundError: src` | `docker compose exec airflow-scheduler python -c "import src.load_raw"` | Project root not on Python path | Confirm `PYTHONPATH=/opt/airflow` and `./src:/opt/airflow/src` |
| SQL template not found | `docker compose exec airflow-scheduler ls -l /opt/airflow/sql` | SQL directory mount/path mismatch | Confirm `./sql:/opt/airflow/sql`; DAG references `sql/00_init.sql` |
| Postgres connection refused | `docker compose ps` and `docker compose logs postgres` | Database not healthy or wrong hostname | Wait for health check; use service hostname `postgres` inside containers |
| Postgres password failure | `docker compose exec airflow-scheduler airflow connections get flights_postgres` | `.env` password and connection URI differ | Align `POSTGRES_USER` and `POSTGRES_PASSWORD`; recreate DB volume only if safe |
| Airflow metadata DB error | `docker compose logs airflow-init` | `airflow` database/role not initialized | Check init script and Postgres logs; init scripts run only on an empty volume |
| OpenSky HTTP 401 | Inspect task log without printing secrets | Missing/invalid OAuth credentials or access restrictions | Verify client credentials and OpenSky account/API access |
| OpenSky HTTP 429 | Inspect task log and retry timing | API rate/credit limit | Reduce manual requests and keep hourly schedule; respect API terms |
| Duplicate fact rows | Run duplicate-key query in `sql/06_analytics.sql` | Unique constraint missing or load bypasses UPSERT | Confirm unique constraint and `ON CONFLICT` in `sql/05_transform.sql` |

## Useful commands

```bash
docker compose config
docker compose ps
docker compose logs --tail=100 postgres
docker compose logs --tail=100 airflow-scheduler
docker compose exec airflow-scheduler airflow dags list
docker compose exec airflow-scheduler airflow dags list-import-errors
docker compose exec airflow-scheduler airflow tasks list opensky_flight_elt
docker compose exec postgres psql -U pipeline_user -d flights_dw -c "SELECT count(*) FROM raw.opensky_api_response;"
docker compose exec postgres psql -U pipeline_user -d flights_dw -c "SELECT count(*) FROM warehouse.fact_flight_position;"
```

## Actual issue log

| Date | Symptom observed | Root cause confirmed | Fix applied | Evidence |
|---|---|---|---|---|
| Add only after reproducing | | | | |
