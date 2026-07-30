
-- =========================================================
-- View 1: analytics.fact_customer_support_impact
-- Grain : One row per support request
--
-- 功能：
-- 1. 判斷 Request 當天是否能歸因到特定 phone_id
-- 2. 區分：
--    - 沒有有效訂閱
--    - 多支有效門號，無法判斷
--    - 同一門號有重疊訂閱，資料異常
--    - 唯一有效門號與訂閱
-- 3. 找同門號的下一筆訂閱
-- 4. 判斷立即續訂、回流、流失、尚未到期
-- 5. 判斷維持方案、升級、降級
-- =========================================================

CREATE VIEW analytics.fact_customer_support_impact AS

WITH plan_ranking AS (
    SELECT *
    FROM (
        VALUES
            ('Basic28',       1, 'Basic',     28),
            ('Basic365',      2, 'Basic',    365),
            ('DataPlus28',    3, 'DataPlus',  28),
            ('DataPlus365',   4, 'DataPlus', 365),
            ('Unlimited28',   5, 'Unlimited', 28),
            ('Unlimited365',  6, 'Unlimited',365)
    ) AS x(
        plan_name,
        plan_rank,
        plan_tier,
        plan_cycle_days
    )
),

data_boundary AS (
    /*
      資料截止日使用已實際觀察到的事件日期。

      不使用 MAX(subscription.end_date)，因為 end_date
      可能落在資料最後事件日期之後。
    */
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

request_base AS (
    SELECT
        sr.request_id,
        sr.customer_id,
        sr.csr_id,
        sr.request_type,

        sr.open_time,
        sr.closed_time,
        sr.open_time::DATE AS request_date,

        CASE
            WHEN sr.closed_time IS NOT NULL
            THEN EXTRACT(
                EPOCH FROM (sr.closed_time - sr.open_time)
            ) / 60.0
        END AS resolution_minutes,

        c.date_of_birth,

        EXTRACT(
            YEAR FROM AGE(
                sr.open_time::DATE,
                c.date_of_birth
            )
        )::INTEGER AS age_at_request

    FROM raw.support_requests AS sr

    JOIN raw.customers AS c
        ON c.customer_id = sr.customer_id
),

request_active_counts AS (
    /*
      計算 Request 當天：
      - 有幾筆有效訂閱
      - 涉及幾支不同門號
    */
    SELECT
        rb.request_id,
        COUNT(s.subscription_id)::INTEGER
            AS active_subscription_count,

        COUNT(DISTINCT s.phone_id)::INTEGER
            AS active_phone_count

    FROM request_base AS rb

    LEFT JOIN raw.subscriptions AS s
        ON s.customer_id = rb.customer_id
       AND rb.request_date
           BETWEEN s.start_date AND s.end_date

    GROUP BY rb.request_id
),

request_with_active_subscription AS (
    SELECT
        rb.*,

        rac.active_subscription_count,
        rac.active_phone_count,

        active.subscription_id
            AS subscription_id_at_request,

        active.phone_id
            AS phone_id_at_request,

        active.plan_id
            AS plan_id_at_request,

        active.plan_name
            AS plan_name_at_request,

        active.plan_rank
            AS plan_rank_at_request,

        active.plan_tier
            AS plan_tier_at_request,

        active.plan_cycle_days
            AS plan_cycle_days_at_request,

        active.plan_price
            AS plan_price_at_request,

        active.subscription_start_date,
        active.subscription_end_date

    FROM request_base AS rb

    JOIN request_active_counts AS rac
        ON rac.request_id = rb.request_id

    /*
      只有恰好一筆有效訂閱且一支有效門號時，
      才實際填入 phone_id 與方案資料。
    */
    LEFT JOIN LATERAL (
        SELECT
            s.subscription_id,
            s.phone_id,
            s.plan_id,

            p.plan_name,
            p.price AS plan_price,

            pr.plan_rank,
            pr.plan_tier,
            pr.plan_cycle_days,

            s.start_date AS subscription_start_date,
            s.end_date AS subscription_end_date

        FROM raw.subscriptions AS s

        JOIN raw.plans AS p
            ON p.plan_id = s.plan_id

        LEFT JOIN plan_ranking AS pr
            ON pr.plan_name = p.plan_name

        WHERE s.customer_id = rb.customer_id
          AND rb.request_date
              BETWEEN s.start_date AND s.end_date
          AND rac.active_subscription_count = 1
          AND rac.active_phone_count = 1

        LIMIT 1
    ) AS active
        ON TRUE
),

request_with_next_subscription AS (
    SELECT
        rwa.*,

        next_sub.subscription_id
            AS next_subscription_id,

        next_sub.plan_id
            AS next_plan_id,

        next_sub.plan_name
            AS next_plan_name,

        next_sub.plan_rank
            AS next_plan_rank,

        next_sub.plan_tier
            AS next_plan_tier,

        next_sub.plan_cycle_days
            AS next_plan_cycle_days,

        next_sub.plan_price
            AS next_plan_price,

        next_sub.start_date
            AS next_subscription_start_date,

        next_sub.end_date
            AS next_subscription_end_date

    FROM request_with_active_subscription AS rwa

    /*
      對唯一歸因的門號，尋找時間上的下一筆訂閱。
    */
    LEFT JOIN LATERAL (
        SELECT
            s2.subscription_id,
            s2.plan_id,

            p2.plan_name,
            p2.price AS plan_price,

            pr2.plan_rank,
            pr2.plan_tier,
            pr2.plan_cycle_days,

            s2.start_date,
            s2.end_date

        FROM raw.subscriptions AS s2

        JOIN raw.plans AS p2
            ON p2.plan_id = s2.plan_id

        LEFT JOIN plan_ranking AS pr2
            ON pr2.plan_name = p2.plan_name

        WHERE rwa.phone_id_at_request IS NOT NULL
          AND s2.phone_id = rwa.phone_id_at_request
          AND s2.subscription_id
              <> rwa.subscription_id_at_request
          AND s2.start_date
              > rwa.subscription_start_date

        ORDER BY
            s2.start_date,
            s2.subscription_id

        LIMIT 1
    ) AS next_sub
        ON TRUE
)

SELECT
    rwn.request_id,
    rwn.customer_id,
    rwn.csr_id,
    rwn.request_type,

    rwn.open_time,
    rwn.closed_time,
    rwn.request_date,

    ROUND(rwn.resolution_minutes, 2)
        AS resolution_minutes,

    rwn.age_at_request,

    CASE
        WHEN rwn.age_at_request IS NULL
            THEN 'Unknown'
        WHEN rwn.age_at_request < 18
            THEN 'Under 18'
        WHEN rwn.age_at_request <= 24
            THEN '18-24'
        WHEN rwn.age_at_request <= 34
            THEN '25-34'
        WHEN rwn.age_at_request <= 44
            THEN '35-44'
        WHEN rwn.age_at_request <= 54
            THEN '45-54'
        WHEN rwn.age_at_request <= 64
            THEN '55-64'
        ELSE '65+'
    END AS age_group_at_request,

    rwn.active_subscription_count,
    rwn.active_phone_count,

    /*
      Request 歸因狀態：各分類互斥。
    */
    CASE
        WHEN rwn.active_subscription_count = 0
            THEN 'No Active Subscription'

        WHEN rwn.active_phone_count > 1
            THEN 'Ambiguous Multiple Active Phones'

        WHEN rwn.active_phone_count = 1
         AND rwn.active_subscription_count > 1
            THEN 'Data Issue - Overlapping Subscriptions'

        WHEN rwn.active_phone_count = 1
         AND rwn.active_subscription_count = 1
            THEN 'Unique Active Subscription'

        ELSE 'Not Evaluated'
    END AS phone_assignment_status,

    /*
      是否可進行門號後續分析。
    */
    CASE
        WHEN rwn.active_phone_count = 1
         AND rwn.active_subscription_count = 1
        THEN TRUE
        ELSE FALSE
    END AS attributable_phone_flag,

    rwn.subscription_id_at_request,
    rwn.phone_id_at_request,

    rwn.plan_id_at_request,
    rwn.plan_name_at_request,
    rwn.plan_rank_at_request,
    rwn.plan_tier_at_request,
    rwn.plan_cycle_days_at_request,
    rwn.plan_price_at_request,

    rwn.subscription_start_date,
    rwn.subscription_end_date,

    rwn.next_subscription_id,
    rwn.next_plan_id,
    rwn.next_plan_name,
    rwn.next_plan_rank,
    rwn.next_plan_tier,
    rwn.next_plan_cycle_days,
    rwn.next_plan_price,

    rwn.next_subscription_start_date,
    rwn.next_subscription_end_date,

    CASE
        WHEN rwn.next_subscription_start_date IS NOT NULL
        THEN
            rwn.next_subscription_start_date
            - rwn.subscription_end_date
    END AS gap_days_after_expiry,

    /*
      後續訂閱狀態。
    */
    CASE
        WHEN rwn.active_phone_count <> 1
          OR rwn.active_subscription_count <> 1
            THEN 'Not Evaluated'

        WHEN rwn.next_subscription_id IS NOT NULL
            THEN 'Later Subscription Found'

        ELSE 'No Later Subscription Found'
    END AS followup_status,

    /*
      生命週期分類。

      Immediate Renewal：
      下一筆訂閱於本期結束日當天或隔天開始。

      Returned After Gap：
      同一門號之後有訂閱，但中間曾中斷。

      Churn：
      本期已到期，而且沒有後續訂閱。

      Active at Data End：
      沒有後續訂閱，但本期在資料截止日仍有效。
    */
    CASE
        WHEN rwn.active_phone_count <> 1
          OR rwn.active_subscription_count <> 1
            THEN 'Not Evaluated'

        WHEN rwn.next_subscription_id IS NOT NULL
         AND rwn.next_subscription_start_date
                <= rwn.subscription_end_date + 1
            THEN 'Immediate Renewal'

        WHEN rwn.next_subscription_id IS NOT NULL
         AND rwn.next_subscription_start_date
                > rwn.subscription_end_date + 1
            THEN 'Returned After Gap'

        WHEN rwn.next_subscription_id IS NULL
         AND rwn.subscription_end_date
                <= db.data_end_date
            THEN 'Churn'

        WHEN rwn.next_subscription_id IS NULL
         AND rwn.subscription_end_date
                > db.data_end_date
            THEN 'Active at Data End'

        ELSE 'Not Evaluated'
    END AS lifecycle_status,

    /*
      方案變化分類。
      使用你指定的方案排序。
    */
    CASE
        WHEN rwn.active_phone_count <> 1
          OR rwn.active_subscription_count <> 1
            THEN 'Not Evaluated'

        WHEN rwn.next_subscription_id IS NULL
            THEN 'No Later Plan'

        WHEN rwn.next_plan_id =
             rwn.plan_id_at_request
            THEN 'Retained Same Plan'

        WHEN rwn.next_plan_rank >
             rwn.plan_rank_at_request
            THEN 'Upgrade'

        WHEN rwn.next_plan_rank <
             rwn.plan_rank_at_request
            THEN 'Downgrade'

        ELSE 'Changed Plan - Unclassified'
    END AS plan_change_status,

    CASE
        WHEN rwn.active_phone_count = 1
         AND rwn.active_subscription_count = 1
         AND rwn.next_subscription_id IS NOT NULL
         AND rwn.next_subscription_start_date
                <= rwn.subscription_end_date + 1
        THEN TRUE
        ELSE FALSE
    END AS immediate_renewal_flag,

    CASE
        WHEN rwn.active_phone_count = 1
         AND rwn.active_subscription_count = 1
         AND rwn.next_subscription_id IS NOT NULL
         AND rwn.next_subscription_start_date
                > rwn.subscription_end_date + 1
        THEN TRUE
        ELSE FALSE
    END AS returned_after_gap_flag,

    CASE
        WHEN rwn.active_phone_count = 1
         AND rwn.active_subscription_count = 1
         AND rwn.next_subscription_id IS NULL
         AND rwn.subscription_end_date
                <= db.data_end_date
        THEN TRUE
        ELSE FALSE
    END AS churn_flag,

    CASE
        WHEN rwn.active_phone_count = 1
         AND rwn.active_subscription_count = 1
         AND rwn.next_subscription_id IS NULL
         AND rwn.subscription_end_date
                > db.data_end_date
        THEN TRUE
        ELSE FALSE
    END AS active_at_data_end_flag,

    db.data_end_date

FROM request_with_next_subscription AS rwn

CROSS JOIN data_boundary AS db;
