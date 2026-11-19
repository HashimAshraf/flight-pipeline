from __future__ import annotations
from pathlib import Path
import psycopg2
import sqlparse
from src.config import database_config

PROJECT_ROOT = Path(__file__).resolve().parents[1]

def transform_raw(raw_id: int) -> None:
    sql_text = (PROJECT_ROOT / "sql" / "05_transform.sql").read_text(encoding="utf-8")
    statements = [statement.strip() for statement in sqlparse.split(sql_text) if statement.strip()]
    conn = psycopg2.connect(**database_config())
    try:
        with conn:
            with conn.cursor() as cur:
                for statement in statements:
                    cur.execute(statement, {"raw_id": raw_id})
    finally:
        conn.close()

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="Transform one raw OpenSky response")
    parser.add_argument("--raw-id", type=int, required=True)
    args = parser.parse_args()
    transform_raw(args.raw_id)
    print(f"Transformed raw_id={args.raw_id}")
