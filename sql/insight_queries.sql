-- 1. Customer registrations in 2023 and 2024 by age bucket
WITH customer_age AS (
    SELECT
        customer_id,
        CAST(strftime('%Y', '2025-01-01') AS INTEGER)
            - CAST(strftime('%Y', date_of_birth) AS INTEGER) AS age,
        strftime('%Y', registration_date) AS registration_year
    FROM customers
    WHERE strftime('%Y', registration_date) IN ('2023', '2024')
)
SELECT
    registration_year,
    CASE
        WHEN age <= 20 THEN '<=20'
        WHEN age BETWEEN 21 AND 40 THEN '21-40'
        WHEN age BETWEEN 41 AND 60 THEN '41-60'
        WHEN age BETWEEN 61 AND 80 THEN '61-80'
        ELSE '80+'
    END AS age_bucket,
    COUNT(DISTINCT customer_id) AS unique_customers
FROM customer_age
GROUP BY registration_year, age_bucket
ORDER BY registration_year, age_bucket;


-- 2. Plan popularity and revenue in 2024
SELECT
    strftime('%Y', s.start_date) AS subscription_year,
    p.plan_id,
    p.plan_name,
    COUNT(DISTINCT s.customer_id) AS customer_count,
    COUNT(s.subscription_id) AS subscription_count,
    ROUND(SUM(pay.amount), 2) AS total_revenue
FROM subscriptions s
JOIN plans p
    ON s.plan_id = p.plan_id
JOIN payments pay
    ON s.subscription_id = pay.subscription_id
WHERE strftime('%Y', s.start_date) = '2024'
GROUP BY subscription_year, p.plan_id, p.plan_name
ORDER BY total_revenue DESC;


-- 3. Preferred payment method by age group in 2024
WITH payment_age_groups AS (
    SELECT
        c.customer_id,
        pay.payment_method,
        CASE
            WHEN CAST(strftime('%Y', '2025-01-01') AS INTEGER)
                - CAST(strftime('%Y', c.date_of_birth) AS INTEGER) <= 20 THEN '<=20'
            WHEN CAST(strftime('%Y', '2025-01-01') AS INTEGER)
                - CAST(strftime('%Y', c.date_of_birth) AS INTEGER) BETWEEN 21 AND 40 THEN '21-40'
            WHEN CAST(strftime('%Y', '2025-01-01') AS INTEGER)
                - CAST(strftime('%Y', c.date_of_birth) AS INTEGER) BETWEEN 41 AND 60 THEN '41-60'
            WHEN CAST(strftime('%Y', '2025-01-01') AS INTEGER)
                - CAST(strftime('%Y', c.date_of_birth) AS INTEGER) BETWEEN 61 AND 80 THEN '61-80'
            ELSE '80+'
        END AS age_group
    FROM customers c
    JOIN payments pay
        ON c.customer_id = pay.customer_id
    WHERE strftime('%Y', pay.payment_date) = '2024'
)
SELECT
    age_group,
    payment_method,
    COUNT(*) AS payment_count
FROM payment_age_groups
GROUP BY age_group, payment_method
ORDER BY age_group, payment_count DESC;


-- 4. Support request volume and average resolution time
SELECT
    request_type,
    COUNT(*) AS request_count,
    ROUND(AVG(strftime('%s', closed_time) - strftime('%s', open_time)) / 3600.0, 2)
        AS avg_resolution_hours
FROM support_requests
WHERE open_time IS NOT NULL
  AND closed_time IS NOT NULL
GROUP BY request_type
ORDER BY request_count DESC;


-- 5. Support workload split by employment type in 2024
WITH request_counts AS (
    SELECT
        request_type,
        COUNT(request_id) AS total_requests
    FROM support_requests
    WHERE strftime('%Y', closed_time) = '2024'
    GROUP BY request_type
),
csr_request_counts AS (
    SELECT
        sr.request_type,
        csr.employment_type,
        COUNT(sr.request_id) AS employment_requests
    FROM support_requests sr
    JOIN customer_service_rep csr
        ON sr.csr_id = csr.csr_id
    WHERE strftime('%Y', sr.closed_time) = '2024'
    GROUP BY sr.request_type, csr.employment_type
)
SELECT
    crc.request_type,
    crc.employment_type,
    crc.employment_requests,
    rc.total_requests,
    ROUND(crc.employment_requests * 100.0 / rc.total_requests, 2) AS percentage_of_type
FROM csr_request_counts crc
JOIN request_counts rc
    ON crc.request_type = rc.request_type
ORDER BY crc.request_type, crc.employment_type;
