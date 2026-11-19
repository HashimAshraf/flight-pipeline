from __future__ import annotations
import os
from dotenv import load_dotenv

load_dotenv()

def api_config() -> dict:
    return {
        "client_id": os.getenv("OPENSKY_CLIENT_ID", ""),
        "client_secret": os.getenv("OPENSKY_CLIENT_SECRET", ""),
        "lamin": float(os.getenv("BBOX_LAMIN", "24.0")),
        "lamax": float(os.getenv("BBOX_LAMAX", "28.0")),
        "lomin": float(os.getenv("BBOX_LOMIN", "66.0")),
        "lomax": float(os.getenv("BBOX_LOMAX", "70.0")),
    }

def database_config() -> dict:
    return {
        "host": os.getenv("POSTGRES_HOST", "localhost"),
        "port": int(os.getenv("POSTGRES_PORT", "5432")),
        "dbname": os.getenv("POSTGRES_DB", "flights_dw"),
        "user": os.getenv("POSTGRES_USER", "pipeline_user"),
        "password": os.getenv("POSTGRES_PASSWORD", "pipeline_dev_only"),
    }
