-- Run connected to flights_dw:
--   psql -U pipeline_user -d flights_dw -f sql/01_schemas.sql
CREATE SCHEMA IF NOT EXISTS raw;        -- API responses, stored untouched
CREATE SCHEMA IF NOT EXISTS staging;    -- typed, validated, cleaned rows
CREATE SCHEMA IF NOT EXISTS warehouse;  -- star schema for analytics
