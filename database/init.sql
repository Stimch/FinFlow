-- FinFlow Database Initialization Script
-- Выполняет все скрипты в правильном порядке

\echo 'Creating database schema...'
\i 01_schema.sql

\echo 'Creating functions...'
\i 02_functions.sql

\echo 'Creating triggers...'
\i 03_triggers.sql

\echo 'Creating views...'
\i 04_views.sql

\echo 'Creating additional indexes...'
\i 06_indexes_analysis.sql

\echo 'Database initialization completed!'
\echo 'To load test data, run: psql -d finflow -f 05_seed_data.sql'





