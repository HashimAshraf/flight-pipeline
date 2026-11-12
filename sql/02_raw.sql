-- RAW LAYER: one row per API call, payload stored exactly as received.
CREATE TABLE IF NOT EXISTS raw.opensky_api_response (
    raw_id          BIGSERIAL PRIMARY KEY,
    ingested_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    api_time        BIGINT,                 -- "time" field from the response (unix seconds)
    request_params  JSONB,                  -- bounding box etc.
    state_count     INTEGER,
    payload         JSONB NOT NULL          -- full JSON response
);

CREATE INDEX IF NOT EXISTS idx_raw_ingested_at ON raw.opensky_api_response (ingested_at);
