-- Create main schema in the app_dev database
CREATE SCHEMA IF NOT EXISTS main;
GRANT ALL ON SCHEMA main TO app;
ALTER ROLE app SET search_path = main, public;

-- Set default privileges in main schema for the app role
ALTER DEFAULT PRIVILEGES FOR USER app IN SCHEMA main GRANT ALL ON TABLES TO app;
ALTER DEFAULT PRIVILEGES FOR USER app IN SCHEMA main GRANT ALL ON SEQUENCES TO app;

CREATE EXTENSION IF NOT EXISTS citext SCHEMA main;

-- Create test database for automated testing
CREATE DATABASE app_test ENCODING 'UTF-8' LC_COLLATE 'C' LC_CTYPE 'C';

-- Grant privileges to test user
GRANT ALL PRIVILEGES ON DATABASE app_test TO app;

-- Connect to test database and setup main schema
\c app_test

CREATE SCHEMA IF NOT EXISTS main;
GRANT ALL ON SCHEMA main TO app;
ALTER ROLE app SET search_path = main, public;

-- Set default privileges in main schema for the app role in test
ALTER DEFAULT PRIVILEGES FOR USER app IN SCHEMA main GRANT ALL ON TABLES TO app;
ALTER DEFAULT PRIVILEGES FOR USER app IN SCHEMA main GRANT ALL ON SEQUENCES TO app;

CREATE EXTENSION IF NOT EXISTS citext SCHEMA main;
