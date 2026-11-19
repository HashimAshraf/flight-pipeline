CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS warehouse;

CREATE TABLE IF NOT EXISTS raw.opensky_api_response (
    raw_id BIGSERIAL PRIMARY KEY,
    ingested_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    api_time BIGINT,
    request_params JSONB,
    state_count INTEGER,
    payload JSONB NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_raw_ingested_at
    ON raw.opensky_api_response(ingested_at);

CREATE TABLE IF NOT EXISTS staging.opensky_states (
    stg_id BIGSERIAL PRIMARY KEY,
    raw_id BIGINT NOT NULL REFERENCES raw.opensky_api_response(raw_id),
    icao24 VARCHAR(6) NOT NULL,
    callsign VARCHAR(8),
    origin_country TEXT,
    time_position TIMESTAMPTZ,
    last_contact TIMESTAMPTZ,
    longitude DOUBLE PRECISION,
    latitude DOUBLE PRECISION,
    baro_altitude DOUBLE PRECISION,
    geo_altitude DOUBLE PRECISION,
    velocity DOUBLE PRECISION,
    true_track DOUBLE PRECISION,
    vertical_rate DOUBLE PRECISION,
    on_ground BOOLEAN,
    squawk VARCHAR(4),
    spi BOOLEAN,
    position_source SMALLINT,
    is_valid BOOLEAN NOT NULL DEFAULT TRUE,
    reject_reason TEXT,
    loaded_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX IF NOT EXISTS uq_staging_icao_position
    ON staging.opensky_states(icao24, time_position)
    WHERE time_position IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_staging_raw_id ON staging.opensky_states(raw_id);
CREATE INDEX IF NOT EXISTS idx_staging_valid ON staging.opensky_states(is_valid);

CREATE TABLE IF NOT EXISTS warehouse.dim_date (
    date_key INTEGER PRIMARY KEY,
    full_date DATE NOT NULL UNIQUE,
    year SMALLINT NOT NULL,
    month SMALLINT NOT NULL,
    day SMALLINT NOT NULL,
    day_of_week SMALLINT NOT NULL,
    is_weekend BOOLEAN NOT NULL
);
CREATE TABLE IF NOT EXISTS warehouse.dim_aircraft (
    aircraft_key SERIAL PRIMARY KEY,
    icao24 VARCHAR(6) NOT NULL UNIQUE,
    callsign VARCHAR(8),
    origin_country TEXT,
    first_seen_at TIMESTAMPTZ,
    last_seen_at TIMESTAMPTZ
);
CREATE TABLE IF NOT EXISTS warehouse.fact_flight_position (
    position_key BIGSERIAL PRIMARY KEY,
    aircraft_key INTEGER NOT NULL REFERENCES warehouse.dim_aircraft(aircraft_key),
    date_key INTEGER NOT NULL REFERENCES warehouse.dim_date(date_key),
    position_ts TIMESTAMPTZ NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    baro_altitude DOUBLE PRECISION,
    geo_altitude DOUBLE PRECISION,
    velocity DOUBLE PRECISION,
    true_track DOUBLE PRECISION,
    vertical_rate DOUBLE PRECISION,
    on_ground BOOLEAN,
    loaded_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_fact_aircraft_ts UNIQUE (aircraft_key, position_ts)
);
CREATE INDEX IF NOT EXISTS idx_fact_date ON warehouse.fact_flight_position(date_key);
CREATE INDEX IF NOT EXISTS idx_fact_ts ON warehouse.fact_flight_position(position_ts);
