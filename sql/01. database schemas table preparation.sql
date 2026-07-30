/* create_schemas */
CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS analytics;

/* create_tables */
CREATE TABLE raw.customers (
    customer_id VARCHAR(8) PRIMARY KEY,
    registration_date DATE NOT NULL,
    date_of_birth DATE NOT NULL,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL,
    address TEXT NOT NULL
);

SELECT
    column_name,
    data_type,
    character_maximum_length,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'raw'
  AND table_name = 'customers'
ORDER BY ordinal_position;