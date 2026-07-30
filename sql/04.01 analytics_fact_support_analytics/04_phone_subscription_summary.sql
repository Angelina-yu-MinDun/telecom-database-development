-- =========================================================
-- View 3: analytics.phone_subscription_summary
-- Grain : One row per phone_id
--
-- 功能：
-- 1. 以所有 raw.phone 為母體，不只包含詢問過客服的電話
-- 2. 判斷門號是否曾經訂閱
-- 3. 判斷門號目前是有效或已流失
-- 4. 判斷歷史上是否曾立即續訂、回流
-- 5. 判斷該門號是否曾有可唯一歸因的客服 Request
-- 6. 保留最近一次可歸因 Request Type
--
-- 注意：
-- 「電話曾詢問客服」僅指能唯一歸因到該電話的 Request。
-- 無法歸因的多門號 Request 不會任意分配給某支電話。
-- =========================================================

CREATE VIEW analytics.phone_subscription_summary AS

WITH plan_ranking AS (
    SELECT *
    FROM (
        VALUES
            ('Basic28',       1, 'Basic',      28),
            ('Basic365',      2, 'Basic',     365),
            ('DataPlus28',    3, 'DataPlus',   28),
            ('DataPlus365',   4, 'DataPlus',  365),
            ('Unlimited28',   5, 'Unlimited',  28),
            ('Unlimited365',  6, 'Unlimited', 365)
    ) AS x(
        plan_name,
        plan_rank,
        plan_tier,
        plan_cycle_days
    )
),

data_boundary AS (
    SELECT
        GREATEST(
            COALESCE(
                (SELECT MAX(s.start_date)
                 FROM raw.subscriptions AS s),
                DATE '1900-01-01'
            ),
            COALESCE(
                (SELECT MAX(p.payment_date)
                 FROM raw.payments AS p),
                DATE '1900-01-01'
            ),
            COALESCE(
                (SELECT MAX(sr.open_time::DATE)
                 FROM raw.support_requests AS sr),
                DATE '1900-01-01'
            )
        ) AS data_end_date
),

subscription_sequence AS (
    /*
      對每支門號的所有訂閱依時間排序，
      並取得上一期及下一期資訊。
    */
    SELECT
        s.subscription_id,
        s.customer_id,
        s.phone_id,
        s.plan_id,
        s.start_date,
        s.end_date,

        p.plan_name,
        p.price AS plan_price,

        pr.plan_rank,
        pr.plan_tier,
        pr.plan_cycle_days,

        LAG(s.subscription_id) OVER (
            PARTITION BY s.phone_id
            ORDER BY s.start_date, s.subscription_id
        ) AS previous_subscription_id,

        LAG(s.end_date) OVER (
            PARTITION BY s.phone_id
            ORDER BY s.start_date, s.subscription_id
        ) AS previous_subscription_end_date,

        LEAD(s.subscription_id) OVER (
            PARTITION BY s.phone_id
            ORDER BY s.start_date, s.subscription_id
        ) AS next_subscription_id,

        LEAD(s.start_date) OVER (
            PARTITION BY s.phone_id
            ORDER BY s.start_date, s.subscription_id
        ) AS next_subscription_start_date,

        ROW_NUMBER() OVER (
            PARTITION BY s.phone_id
            ORDER BY
                s.start_date DESC,
                s.subscription_id DESC
        ) AS latest_subscription_rank

    FROM raw.subscriptions AS s

    JOIN raw.plans AS p
        ON p.plan_id = s.plan_id

    LEFT JOIN plan_ranking AS pr
        ON pr.plan_name = p.plan_name
),

phone_subscription_history AS (
    SELECT
        ss.phone_id,

        COUNT(*)::INTEGER
            AS subscription_count,

        MIN(ss.start_date)
            AS first_subscription_start_date,

        MAX(ss.end_date)
            AS latest_recorded_end_date,

        BOOL_OR(
            ss.next_subscription_start_date IS NOT NULL
            AND ss.next_subscription_start_date
                <= ss.end_date + 1
        ) AS ever_immediate_renewal_flag,

        BOOL_OR(
            ss.next_subscription_start_date IS NOT NULL
            AND ss.next_subscription_start_date
                > ss.end_date + 1
        ) AS ever_returned_after_gap_flag,

        MAX(
            CASE
                WHEN ss.next_subscription_start_date IS NOT NULL
                THEN ss.next_subscription_start_date - ss.end_date
            END
        ) AS maximum_gap_days

    FROM subscription_sequence AS ss

    GROUP BY ss.phone_id
),

latest_subscription AS (
    SELECT
        ss.*
    FROM subscription_sequence AS ss
    WHERE ss.latest_subscription_rank = 1
),

attributed_support_aggregate AS (
    /*
      只使用能唯一歸因到 phone_id 的客服 Request。
    */
    SELECT
        f.phone_id_at_request AS phone_id,

        COUNT(*)::INTEGER
            AS attributed_support_request_count,

        COUNT(DISTINCT f.request_type)::INTEGER
            AS attributed_request_type_count,

        MIN(f.open_time)
            AS first_attributed_request_time,

        MAX(f.open_time)
            AS last_attributed_request_time

    FROM analytics.fact_customer_support_impact AS f

    WHERE f.attributable_phone_flag = TRUE

    GROUP BY f.phone_id_at_request
),

latest_attributed_request AS (
    SELECT
        f.phone_id_at_request AS phone_id,
        f.request_id,
        f.request_type,
        f.request_date,

        ROW_NUMBER() OVER (
            PARTITION BY f.phone_id_at_request
            ORDER BY
                f.open_time DESC,
                f.request_id DESC
        ) AS request_rank

    FROM analytics.fact_customer_support_impact AS f

    WHERE f.attributable_phone_flag = TRUE
),

customer_support_aggregate AS (
    /*
      顧客層級是否曾詢問客服。
      此欄位不能等同於特定門號詢問客服，
      僅作補充資訊。
    */
    SELECT
        sr.customer_id,
        COUNT(*)::INTEGER
            AS customer_total_request_count

    FROM raw.support_requests AS sr

    GROUP BY sr.customer_id
)

SELECT
    ph.phone_id,
    ph.customer_id,
    ph.phone_number,
    ph.activation_date,

    COALESCE(psh.subscription_count, 0)
        AS subscription_count,

    psh.first_subscription_start_date,
    psh.latest_recorded_end_date,

    ls.subscription_id
        AS latest_subscription_id,

    ls.plan_id
        AS latest_plan_id,

    ls.plan_name
        AS latest_plan_name,

    ls.plan_rank
        AS latest_plan_rank,

    ls.plan_tier
        AS latest_plan_tier,

    ls.plan_cycle_days
        AS latest_plan_cycle_days,

    ls.plan_price
        AS latest_plan_price,

    ls.start_date
        AS latest_subscription_start_date,

    ls.end_date
        AS latest_subscription_end_date,

    /*
      目前門號狀態是依最新一筆訂閱判斷。
    */
    CASE
        WHEN ls.subscription_id IS NULL
            THEN 'Never Subscribed'

        WHEN ls.end_date <= db.data_end_date
            THEN 'Churn'

        WHEN ls.start_date <= db.data_end_date
         AND ls.end_date > db.data_end_date
            THEN 'Active at Data End'

        WHEN ls.start_date > db.data_end_date
            THEN 'Future Subscription'

        ELSE 'Unclassified'
    END AS current_phone_status,

    CASE
        WHEN ls.subscription_id IS NOT NULL
         AND ls.end_date <= db.data_end_date
        THEN TRUE
        ELSE FALSE
    END AS current_churn_flag,

    CASE
        WHEN ls.subscription_id IS NOT NULL
         AND ls.start_date <= db.data_end_date
         AND ls.end_date > db.data_end_date
        THEN TRUE
        ELSE FALSE
    END AS current_active_flag,

    COALESCE(
        psh.ever_immediate_renewal_flag,
        FALSE
    ) AS ever_immediate_renewal_flag,

    COALESCE(
        psh.ever_returned_after_gap_flag,
        FALSE
    ) AS ever_returned_after_gap_flag,

    psh.maximum_gap_days,

    COALESCE(
        asa.attributed_support_request_count,
        0
    ) AS attributed_support_request_count,

    COALESCE(
        asa.attributed_request_type_count,
        0
    ) AS attributed_request_type_count,

    asa.first_attributed_request_time,
    asa.last_attributed_request_time,

    lar.request_id
        AS latest_attributed_request_id,

    lar.request_type
        AS latest_attributed_request_type,

    lar.request_date
        AS latest_attributed_request_date,

    CASE
        WHEN COALESCE(
            asa.attributed_support_request_count,
            0
        ) > 0
        THEN TRUE
        ELSE FALSE
    END AS has_attributed_support_flag,

    CASE
        WHEN COALESCE(
            asa.attributed_support_request_count,
            0
        ) = 0
            THEN 'No Attributed Support'

        WHEN asa.attributed_support_request_count = 1
            THEN 'One Attributed Request'

        ELSE 'Multiple Attributed Requests'
    END AS phone_support_status,

    COALESCE(
        csa.customer_total_request_count,
        0
    ) AS customer_total_request_count,

    CASE
        WHEN COALESCE(
            csa.customer_total_request_count,
            0
        ) > 0
        THEN TRUE
        ELSE FALSE
    END AS customer_has_support_flag,

    db.data_end_date

FROM raw.phone AS ph

LEFT JOIN phone_subscription_history AS psh
    ON psh.phone_id = ph.phone_id

LEFT JOIN latest_subscription AS ls
    ON ls.phone_id = ph.phone_id

LEFT JOIN attributed_support_aggregate AS asa
    ON asa.phone_id = ph.phone_id

LEFT JOIN latest_attributed_request AS lar
    ON lar.phone_id = ph.phone_id
   AND lar.request_rank = 1

LEFT JOIN customer_support_aggregate AS csa
    ON csa.customer_id = ph.customer_id

CROSS JOIN data_boundary AS db;


COMMIT;