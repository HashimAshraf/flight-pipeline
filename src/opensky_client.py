from __future__ import annotations
import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry
from src.config import api_config

API_URL = "https://opensky-network.org/api/states/all"
TOKEN_URL = "https://auth.opensky-network.org/auth/realms/opensky-network/protocol/openid-connect/token"

def build_session() -> requests.Session:
    session = requests.Session()
    retry = Retry(
        total=3, connect=3, read=3, backoff_factor=1,
        status_forcelist=(429, 500, 502, 503, 504),
        allowed_methods=frozenset(["GET", "POST"]),
    )
    session.mount("https://", HTTPAdapter(max_retries=retry))
    session.headers.update({"User-Agent": "opensky-internship-pipeline/1.0"})
    return session

def fetch_states() -> dict:
    cfg = api_config()
    if not (cfg["lamin"] < cfg["lamax"] and cfg["lomin"] < cfg["lomax"]):
        raise ValueError("Invalid bounding box: minimum coordinates must be below maximum coordinates")

    session = build_session()
    headers = {}
    if cfg["client_id"] and cfg["client_secret"]:
        token_response = session.post(
            TOKEN_URL,
            data={
                "grant_type": "client_credentials",
                "client_id": cfg["client_id"],
                "client_secret": cfg["client_secret"],
            },
            timeout=20,
        )
        token_response.raise_for_status()
        headers["Authorization"] = f"Bearer {token_response.json()['access_token']}"

    response = session.get(
        API_URL,
        params={
            "lamin": cfg["lamin"], "lamax": cfg["lamax"],
            "lomin": cfg["lomin"], "lomax": cfg["lomax"],
        },
        headers=headers,
        timeout=30,
    )
    response.raise_for_status()
    payload = response.json()
    if not isinstance(payload, dict) or "states" not in payload:
        raise ValueError("Unexpected OpenSky response: expected a JSON object containing 'states'")
    payload["_request_params"] = {
        "lamin": cfg["lamin"], "lamax": cfg["lamax"],
        "lomin": cfg["lomin"], "lomax": cfg["lomax"],
    }
    return payload
