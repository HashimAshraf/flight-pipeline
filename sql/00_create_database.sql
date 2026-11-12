-- Run ONCE as the postgres superuser, connected to the default "postgres" database:
--   psql -U postgres -f sql/00_create_database.sql
-- Change the password below before running.

DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'pipeline_user') THEN
    CREATE ROLE pipeline_user LOGIN PASSWORD 'change_me';
  END IF;
END
$$;

CREATE DATABASE flights_dw OWNER pipeline_user;
