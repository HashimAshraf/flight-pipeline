-- Convert OpenSky state-vector arrays to typed staging records.
-- OpenSky array positions: 0 ICAO24, 1 callsign, 2 country, 3 position time,
-- 4 last contact, 5 longitude, 6 latitude, 7 baro altitude, 8 on-ground,
-- 9 velocity, 10 track, 11 vertical rate, 13 geo altitude, 14 squawk,
-- 15 SPI, 16 position source.
WITH api_states AS (
    SELECT
        r.raw_id,
        s.state ->> 0 AS icao24,
        NULLIF(btrim(s.state ->> 1), '') AS callsign,
        s.state ->> 2 AS origin_country,
        NULLIF(s.state ->> 3, '')::BIGINT AS time_position_epoch,
        NULLIF(s.state ->> 4, '')::BIGINT AS last_contact_epoch,
        NULLIF(s.state ->> 5, '')::DOUBLE PRECISION AS longitude,
        NULLIF(s.state ->> 6, '')::DOUBLE PRECISION AS latitude,
        NULLIF(s.state ->> 7, '')::DOUBLE PRECISION AS baro_altitude,
        NULLIF(s.state ->> 8, '')::BOOLEAN AS on_ground,
        NULLIF(s.state ->> 9, '')::DOUBLE PRECISION AS velocity,
        NULLIF(s.state ->> 10, '')::DOUBLE PRECISION AS true_track,
        NULLIF(s.state ->> 11, '')::DOUBLE PRECISION AS vertical_rate,
        NULLIF(s.state ->> 13, '')::DOUBLE PRECISION AS geo_altitude,
        NULLIF(s.state ->> 14, '') AS squawk,
        NULLIF(s.state ->> 15, '')::BOOLEAN AS spi,
        NULLIF(s.state ->> 16, '')::SMALLINT AS position_source
    FROM raw.opensky_api_response r
    CROSS JOIN LATERAL jsonb_array_elements(
        CASE WHEN jsonb_typeof(r.payload -> 'states') = 'array'
             THEN r.payload -> 'states' ELSE '[]'::jsonb END
    ) AS s(state)
    WHERE r.raw_id = %(raw_id)s
),
validated AS (
    SELECT *,
        CASE
            WHEN longitude IS NULL OR latitude IS NULL THEN FALSE
            WHEN longitude NOT BETWEEN -180 AND 180 OR latitude NOT BETWEEN -90 AND 90 THEN FALSE
            WHEN time_position_epoch IS NULL OR time_position_epoch <= 0 THEN FALSE
            ELSE TRUE
        END AS is_valid,
        CASE
            WHEN longitude IS NULL OR latitude IS NULL THEN 'missing coordinates'
            WHEN longitude NOT BETWEEN -180 AND 180 OR latitude NOT BETWEEN -90 AND 90 THEN 'coordinates out of range'
            WHEN time_position_epoch IS NULL OR time_position_epoch <= 0 THEN 'missing position timestamp'
            ELSE NULL
        END AS reject_reason
    FROM api_states
    WHERE icao24 IS NOT NULL AND length(icao24) = 6
),
typed AS (
    SELECT
        raw_id, lower(icao24) AS icao24, callsign, origin_country,
        CASE WHEN time_position_epoch > 0 THEN to_timestamp(time_position_epoch) END AS time_position,
        CASE WHEN last_contact_epoch > 0 THEN to_timestamp(last_contact_epoch) END AS last_contact,
        longitude, latitude, baro_altitude, geo_altitude, velocity, true_track,
        vertical_rate, on_ground, squawk, spi, position_source, is_valid, reject_reason
    FROM validated
)
INSERT INTO staging.opensky_states (
    raw_id, icao24, callsign, origin_country, time_position, last_contact,
    longitude, latitude, baro_altitude, geo_altitude, velocity, true_track,
    vertical_rate, on_ground, squawk, spi, position_source, is_valid, reject_reason
)
SELECT
    raw_id, icao24, callsign, origin_country, time_position, last_contact,
    longitude, latitude, baro_altitude, geo_altitude, velocity, true_track,
    vertical_rate, on_ground, squawk, spi, position_source, is_valid, reject_reason
FROM typed
ON CONFLICT (icao24, time_position) WHERE time_position IS NOT NULL
DO UPDATE SET
    raw_id = EXCLUDED.raw_id,
    callsign = EXCLUDED.callsign,
    origin_country = EXCLUDED.origin_country,
    last_contact = EXCLUDED.last_contact,
    longitude = EXCLUDED.longitude,
    latitude = EXCLUDED.latitude,
    baro_altitude = EXCLUDED.baro_altitude,
    geo_altitude = EXCLUDED.geo_altitude,
    velocity = EXCLUDED.velocity,
    true_track = EXCLUDED.true_track,
    vertical_rate = EXCLUDED.vertical_rate,
    on_ground = EXCLUDED.on_ground,
    squawk = EXCLUDED.squawk,
    spi = EXCLUDED.spi,
    position_source = EXCLUDED.position_source,
    is_valid = EXCLUDED.is_valid,
    reject_reason = EXCLUDED.reject_reason;

INSERT INTO warehouse.dim_aircraft
    (icao24, callsign, origin_country, first_seen_at, last_seen_at)
SELECT
    icao24, max(callsign), max(origin_country),
    min(time_position), max(time_position)
FROM staging.opensky_states
WHERE raw_id = %(raw_id)s AND is_valid
GROUP BY icao24
ON CONFLICT (icao24) DO UPDATE SET
    callsign = COALESCE(EXCLUDED.callsign, warehouse.dim_aircraft.callsign),
    origin_country = COALESCE(EXCLUDED.origin_country, warehouse.dim_aircraft.origin_country),
    first_seen_at = CASE
        WHEN warehouse.dim_aircraft.first_seen_at IS NULL THEN EXCLUDED.first_seen_at
        WHEN EXCLUDED.first_seen_at IS NULL THEN warehouse.dim_aircraft.first_seen_at
        ELSE LEAST(warehouse.dim_aircraft.first_seen_at, EXCLUDED.first_seen_at)
    END,
    last_seen_at = CASE
        WHEN warehouse.dim_aircraft.last_seen_at IS NULL THEN EXCLUDED.last_seen_at
        WHEN EXCLUDED.last_seen_at IS NULL THEN warehouse.dim_aircraft.last_seen_at
        ELSE GREATEST(warehouse.dim_aircraft.last_seen_at, EXCLUDED.last_seen_at)
    END;

INSERT INTO warehouse.dim_date
    (date_key, full_date, year, month, day, day_of_week, is_weekend)
SELECT DISTINCT
    to_char(time_position AT TIME ZONE 'UTC', 'YYYYMMDD')::INTEGER,
    (time_position AT TIME ZONE 'UTC')::DATE,
    extract(year FROM time_position AT TIME ZONE 'UTC')::SMALLINT,
    extract(month FROM time_position AT TIME ZONE 'UTC')::SMALLINT,
    extract(day FROM time_position AT TIME ZONE 'UTC')::SMALLINT,
    extract(isodow FROM time_position AT TIME ZONE 'UTC')::SMALLINT,
    extract(isodow FROM time_position AT TIME ZONE 'UTC') IN (6, 7)
FROM staging.opensky_states
WHERE raw_id = %(raw_id)s AND is_valid
ON CONFLICT (date_key) DO NOTHING;

INSERT INTO warehouse.fact_flight_position (
    aircraft_key, date_key, position_ts, longitude, latitude,
    baro_altitude, geo_altitude, velocity, true_track, vertical_rate, on_ground
)
SELECT
    a.aircraft_key,
    to_char(s.time_position AT TIME ZONE 'UTC', 'YYYYMMDD')::INTEGER,
    s.time_position, s.longitude, s.latitude,
    s.baro_altitude, s.geo_altitude, s.velocity, s.true_track,
    s.vertical_rate, s.on_ground
FROM staging.opensky_states s
JOIN warehouse.dim_aircraft a ON a.icao24 = s.icao24
WHERE s.raw_id = %(raw_id)s AND s.is_valid
ON CONFLICT (aircraft_key, position_ts) DO UPDATE SET
    longitude = EXCLUDED.longitude,
    latitude = EXCLUDED.latitude,
    baro_altitude = EXCLUDED.baro_altitude,
    geo_altitude = EXCLUDED.geo_altitude,
    velocity = EXCLUDED.velocity,
    true_track = EXCLUDED.true_track,
    vertical_rate = EXCLUDED.vertical_rate,
    on_ground = EXCLUDED.on_ground;
