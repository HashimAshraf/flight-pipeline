-- WAREHOUSE LAYER: star schema. Fact = position readings; dimensions = aircraft, date.

CREATE TABLE IF NOT EXISTS warehouse.dim_date (
    date_key     INTEGER PRIMARY KEY,       -- yyyymmdd, e.g. 20261112
    full_date    DATE NOT NULL UNIQUE,
    year         SMALLINT NOT NULL,
    month        SMALLINT NOT NULL,
    day          SMALLINT NOT NULL,
    day_of_week  SMALLINT NOT NULL,         -- 1 = Monday ... 7 = Sunday
    is_weekend   BOOLEAN NOT NULL
);

CREATE TABLE IF NOT EXISTS warehouse.dim_aircraft (
    aircraft_key    SERIAL PRIMARY KEY,
    icao24          VARCHAR(6) NOT NULL UNIQUE,   -- natural/business key
    callsign        VARCHAR(8),                   -- most recent seen
    origin_country  TEXT,
    first_seen_at   TIMESTAMPTZ,
    last_seen_at    TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS warehouse.fact_flight_position (
    position_key    BIGSERIAL PRIMARY KEY,
    aircraft_key    INTEGER NOT NULL REFERENCES warehouse.dim_aircraft (aircraft_key),
    date_key        INTEGER NOT NULL REFERENCES warehouse.dim_date (date_key),
    position_ts     TIMESTAMPTZ NOT NULL,         -- time_position from the API
    longitude       DOUBLE PRECISION NOT NULL,
    latitude        DOUBLE PRECISION NOT NULL,
    baro_altitude   DOUBLE PRECISION,
    geo_altitude    DOUBLE PRECISION,
    velocity        DOUBLE PRECISION,
    true_track      DOUBLE PRECISION,
    vertical_rate   DOUBLE PRECISION,
    on_ground       BOOLEAN,
    loaded_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    -- Dedup key: makes UPSERT (ON CONFLICT) idempotent
    CONSTRAINT uq_fact_aircraft_ts UNIQUE (aircraft_key, position_ts)
);

CREATE INDEX IF NOT EXISTS idx_fact_date ON warehouse.fact_flight_position (date_key);
CREATE INDEX IF NOT EXISTS idx_fact_ts   ON warehouse.fact_flight_position (position_ts);
