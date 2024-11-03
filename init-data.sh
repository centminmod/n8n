#!/bin/bash
set -e

# Wait for the database to be ready
until pg_isready -U "${POSTGRES_USER}" -d "${POSTGRES_DB}"; do
  echo "Waiting for database to be ready..."
  sleep 2
done

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Enable required extensions
    CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
    CREATE EXTENSION IF NOT EXISTS "pgcrypto";

    -- Set database configuration
    ALTER SYSTEM SET max_connections = '${POSTGRES_MAX_CONNECTIONS:-100}';
    ALTER SYSTEM SET shared_buffers = '${POSTGRES_SHARED_BUFFERS:-128MB}';
    ALTER SYSTEM SET effective_cache_size = '${POSTGRES_EFFECTIVE_CACHE_SIZE:-384MB}';
    ALTER SYSTEM SET work_mem = '${POSTGRES_WORK_MEM:-16MB}';
    ALTER SYSTEM SET maintenance_work_mem = '${POSTGRES_MAINTENANCE_WORK_MEM:-64MB}';

    -- Grant privileges
    GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO ${POSTGRES_USER};
    GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO ${POSTGRES_USER};
EOSQL

echo "Database initialization completed"