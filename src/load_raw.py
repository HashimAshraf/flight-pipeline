from __future__ import annotations
import json
import psycopg2
from src.config import database_config
from src.opensky_client import fetch_states

def store_raw_payload(payload: dict) -> int:
    conn = psycopg2.connect(**database_config())
    try:
        with conn:
            with conn.cursor() as cur:
                cur.execute(
                    '''
                    INSERT INTO raw.opensky_api_response
                        (api_time, request_params, state_count, payload)
                    VALUES (%s, %s::jsonb, %s, %s::jsonb)
                    RETURNING raw_id
                    ''',
                    (
                        payload.get("time"),
                        json.dumps(payload.get("_request_params", {})),
                        len(payload.get("states") or []),
                        json.dumps(payload),
                    ),
                )
                return int(cur.fetchone()[0])
    finally:
        conn.close()

def extract_and_load() -> int:
    payload = fetch_states()
    return store_raw_payload(payload)

if __name__ == "__main__":
    raw_id = extract_and_load()
    print(f"Stored OpenSky response in raw.opensky_api_response (raw_id={raw_id})")
