-- WEEK 1 ANALYTICAL SQL: CTEs and window functions.

-- 1) CTE: daily observed positions and average speed.
WITH daily_activity AS (
    SELECT
        d.full_date,
        a.icao24,
        count(*) AS position_count,
        round(avg(f.velocity)::numeric, 2) AS avg_velocity_mps,
        round(avg(f.geo_altitude)::numeric, 2) AS avg_geo_altitude_m
    FROM warehouse.fact_flight_position f
    JOIN warehouse.dim_aircraft a USING (aircraft_key)
    JOIN warehouse.dim_date d USING (date_key)
    GROUP BY d.full_date, a.icao24
)
SELECT *
FROM daily_activity
ORDER BY full_date DESC, position_count DESC;

-- 2) LAG and LEAD: compare each aircraft's previous and next observations.
SELECT
    a.icao24,
    f.position_ts,
    f.latitude,
    f.longitude,
    lag(f.position_ts) OVER (PARTITION BY a.icao24 ORDER BY f.position_ts) AS previous_position_ts,
    lead(f.position_ts) OVER (PARTITION BY a.icao24 ORDER BY f.position_ts) AS next_position_ts,
    f.velocity,
    lag(f.velocity) OVER (PARTITION BY a.icao24 ORDER BY f.position_ts) AS previous_velocity
FROM warehouse.fact_flight_position f
JOIN warehouse.dim_aircraft a USING (aircraft_key)
ORDER BY a.icao24, f.position_ts;

-- 3) Staging data-quality summary.
SELECT
    count(*) AS staged_records,
    count(*) FILTER (WHERE is_valid) AS valid_records,
    count(*) FILTER (WHERE NOT is_valid) AS rejected_records
FROM staging.opensky_states;

-- 4) Check duplicate business keys in the fact table (should return zero rows).
SELECT aircraft_key, position_ts, count(*)
FROM warehouse.fact_flight_position
GROUP BY aircraft_key, position_ts
HAVING count(*) > 1;
