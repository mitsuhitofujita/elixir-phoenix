-- Create main schema in app_local database
CREATE SCHEMA IF NOT EXISTS main;
GRANT ALL ON SCHEMA main TO app_local;
ALTER USER app SET search_path TO main, public;

-- Set default privileges in main schema for app_local
ALTER DEFAULT PRIVILEGES FOR USER app IN SCHEMA main GRANT ALL ON TABLES TO app_local;
ALTER DEFAULT PRIVILEGES FOR USER app IN SCHEMA main GRANT ALL ON SEQUENCES TO app_local;

-- Create test database for automated testing
CREATE DATABASE app_testing ENCODING 'UTF-8' LC_COLLATE 'C' LC_CTYPE 'C';

-- Grant privileges to test user
GRANT ALL PRIVILEGES ON DATABASE app_testing TO app;

-- Connect to test database and setup main schema
\c app_testing

CREATE SCHEMA IF NOT EXISTS main;
GRANT ALL ON SCHEMA main TO app_testing;
ALTER USER app SET search_path TO main, public;

-- Set default privileges in main schema for app_testing
ALTER DEFAULT PRIVILEGES FOR USER app IN SCHEMA main GRANT ALL ON TABLES TO app_testing;
ALTER DEFAULT PRIVILEGES FOR USER app IN SCHEMA main GRANT ALL ON SEQUENCES TO app_testing;
