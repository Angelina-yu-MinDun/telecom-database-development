-- =========================================================
-- View 2: analytics.customer_request_summary
-- Grain : One row per customer
--
-- 功能：
-- 1. 客服使用次數
-- 2. 未使用、一次、多次
-- 3. 首次與最近客服日期
-- 4. 最常詢問的客服類型
-- =========================================================
DROP VIEW analytics.customer_request_summary

CREATE OR REPLACE VIEW analytics.customer_request_summary AS

WITH request_aggregate AS (
    SELECT
        c.customer_id,

        COUNT(sr.request_id)::INTEGER
            AS request_count,

        MIN(sr.open_time)
            AS first_request_time,

        MAX(sr.open_time)
            AS last_request_time

    FROM raw.customers AS c

    LEFT JOIN raw.support_requests AS sr
        ON sr.customer_id = c.customer_id

    GROUP BY
        c.customer_id
)

SELECT
    ra.customer_id,

    ra.request_count,
    ra.first_request_time,
    ra.last_request_time,

    CASE
        WHEN ra.request_count = 0
            THEN 'Never Contacted Support'

        WHEN ra.request_count = 1
            THEN 'One-time Support Customer'

        ELSE 'Repeat Support Customer'
    END AS support_customer_status,

    CASE
        WHEN ra.request_count = 0
            THEN '0'

        WHEN ra.request_count = 1
            THEN '1'

        WHEN ra.request_count BETWEEN 2 AND 3
            THEN '2-3'

        ELSE '4+'
    END AS request_frequency_group,

    (ra.request_count > 0)
        AS has_contacted_support_flag,

    (ra.request_count > 1)
        AS repeat_support_flag

FROM request_aggregate AS ra;
