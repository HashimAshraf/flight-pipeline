-- STAGING LAYER: one row per aircraft state vector, typed and validated.
CREATE TABLE IF NOT EXISTS staging.opensky_states (
    stg_id           BIGSERIAL PRIMARY KEY,
    raw_id           BIGINT NOT NULL REFERENCES raw.opensky_api_response (raw_id),
    icao24           VARCHAR(6) NOT NULL,
    callsign         VARCHAR(8),
    origin_country   TEXT,
    time_position    TIMESTAMPTZ,
    last_contact     TIMESTAMPTZ,
    longitude        DOUBLE PRECISION,
    latitude         DOUBLE PRECISION,
    baro_altitude    DOUBLE PRECISION,      -- metres
    geo_altitude     DOUBLE PRECISION,      -- metres
    velocity         DOUBLE PRECISION,      -- m/s
    true_track       DOUBLE PRECISION,      -- degrees clockwise from north
    vertical_rate    DOUBLE PRECISION,      -- m/s
    on_ground        BOOLEAN,
    squawk           VARCHAR(4),
    spi              BOOLEAN,
    position_source  SMALLINT,              -- 0 ADS-B, 1 ASTERIX, 2 MLAT, 3 FLARM
    is_valid         BOOLEAN NOT NULL DEFAULT TRUE,
    reject_reason    TEXT,                  -- e.g. 'null position', 'on ground'
    loaded_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_stg_raw_id   ON staging.opensky_states (raw_id);
CREATE INDEX IF NOT EXISTS idx_stg_dedup    ON staging.opensky_states (icao24, time_position);
CREATE INDEX IF NOT EXISTS idx_stg_valid    ON staging.opensky_states (is_valid);
