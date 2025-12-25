#!/bin/bash
set -e

echo "Initializing FinFlow database..."

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    \echo 'Creating database schema...'
    \i /docker-entrypoint-initdb.d/01_schema.sql
    
    \echo 'Creating functions...'
    \i /docker-entrypoint-initdb.d/02_functions.sql
    
    \echo 'Creating triggers...'
    \i /docker-entrypoint-initdb.d/03_triggers.sql
    
    \echo 'Creating views...'
    \i /docker-entrypoint-initdb.d/04_views.sql
    
    \echo 'Creating additional indexes...'
    \i /docker-entrypoint-initdb.d/06_indexes_analysis.sql
    
    \echo 'Database initialization completed!'
EOSQL

echo "FinFlow database initialized successfully!"





