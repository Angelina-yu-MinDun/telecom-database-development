-- ==============================================
-- 01.analytics.dim_date
-- ==============================================

CREATE OR REPLACE VIEW analytics.dim_date AS
SELECT
    generated_date::DATE AS full_date,
    EXTRACT(YEAR FROM generated_date)::INTEGER AS year,
    EXTRACT(QUARTER FROM generated_date)::INTEGER AS quarter_number,
    'Q' || EXTRACT(QUARTER FROM generated_date)::INTEGER AS quarter_name,
    EXTRACT(MONTH FROM generated_date)::INTEGER AS month_number,
    TO_CHAR(generated_date, 'Mon') AS month_name_short,
    TRIM(TO_CHAR(generated_date, 'Month')) AS month_name_full,
    DATE_TRUNC('month', generated_date)::DATE AS year_month,
    EXTRACT(DAY FROM generated_date)::INTEGER AS day_of_month,
    EXTRACT(ISODOW FROM generated_date)::INTEGER AS day_of_week_number,
    TO_CHAR(generated_date, 'Dy') AS day_name_short,
    TRIM(TO_CHAR(generated_date, 'Day')) AS day_name_full,
    EXTRACT(ISODOW FROM generated_date) IN (6, 7) AS is_weekend
FROM generate_series(
    DATE '2021-12-25',
    DATE '2026-12-31',
    INTERVAL '1 day'
) AS generated_date;


-- ==============================================
-- 02.analytics.dim_customer
-- ==============================================
CREATE OR REPLACE VIEW analytics.dim_customer AS
SELECT
    customer_id,
    name AS customer_name,
    email,
    address,
    date_of_birth,
    registration_date,

    EXTRACT(
        YEAR FROM registration_date
    )::INTEGER AS registration_year,

    DATE_TRUNC(
        'month',
        registration_date
    )::DATE AS registration_month,

    EXTRACT(
        YEAR FROM AGE(registration_date, date_of_birth)
    )::INTEGER AS age_at_registration,

    EXTRACT(
        YEAR FROM AGE(DATE '2025-01-01', date_of_birth)
    )::INTEGER AS age_as_of_2025

FROM raw.customers;

SELECT *
FROM analytics.dim_customer

-- ==============================================
-- 03.analytics.dim_plan
-- ==============================================

CREATE OR REPLACE VIEW analytics.dim_plan AS

SELECT
    plan_id,
    plan_name,
    plan_description,
    plan_duration,
    price

FROM raw.plans;

-- ==============================================
-- 04.analytics.dim_phone
-- ==============================================

CREATE OR REPLACE VIEW analytics.dim_phone AS
SELECT
    phone_id,
    customer_id,
    phone_number,
    activation_date,
    EXTRACT(
        YEAR FROM activation_date
    )::INTEGER AS activation_year,
    DATE_TRUNC(
        'month',
        activation_date
    )::DATE AS activation_month,
    EXTRACT(
        YEAR FROM AGE(
            DATE '2025-01-01',
            activation_date
        )
    )::INTEGER AS phone_age_as_of_2025
FROM raw.phone_number;


-- ==============================================
-- 05.analytics.dim_csr
-- ==============================================

CREATE OR REPLACE VIEW analytics.dim_csr AS
SELECT
    csr_id,
    csr_name,
    employment_type
FROM raw.customer_service_rep;

