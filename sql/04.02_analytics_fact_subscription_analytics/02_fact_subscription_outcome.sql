-- ==============================================
-- analytics.fact_subscription_outcome
-- Grain: one row per subscription
-- ==============================================

CREATE OR REPLACE VIEW analytics.fact_subscription_outcome AS

WITH data_boundary AS (
    /*
      與 fact_customer_support_impact 使用相同的資料截止日邏輯。

      不使用 MAX(subscription.end_date)，因為 end_date 可能是
      已預先排定、但尚未實際觀察到的未來日期。
    */
    SELECT
        GREATEST(
            COALESCE(
                (
                    SELECT MAX(s.start_date)
                    FROM raw.subscriptions AS s
                ),
                DATE '1900-01-01'
            ),

            COALESCE(
                (
                    SELECT MAX(p.payment_date)
                    FROM raw.payments AS p
                ),
                DATE '1900-01-01'
            ),

            COALESCE(
                (
                    SELECT MAX(sr.open_time::DATE)
                    FROM raw.support_requests AS sr
                ),
                DATE '1900-01-01'
            )
        ) AS data_end_date
),

subscription_base AS (
    SELECT
        s.subscription_id,
        s.phone_id,
        ph.customer_id,

        s.plan_id,
        p.plan_name,
        p.plan_description,
        p.plan_duration,
        p.price AS plan_price,

        s.start_date AS subscription_start_date,
        s.end_date AS subscription_end_date,

        /*
          僅作描述，不用來判斷 lifecycle。
          由於目前部分生成資料可能不符合 plan_duration，
          不使用此欄位判定提前解約。
        */
        s.end_date - s.start_date + 1
            AS actual_service_days

    FROM raw.subscriptions AS s

    JOIN raw.phone_number AS ph
        ON ph.phone_id = s.phone_id

    JOIN raw.plans AS p
        ON p.plan_id = s.plan_id
),

subscription_sequence AS (
    SELECT
        sb.*,

        LEAD(sb.subscription_id) OVER (
            PARTITION BY sb.phone_id
            ORDER BY
                sb.subscription_start_date,
                sb.subscription_end_date,
                sb.subscription_id
        ) AS next_subscription_id,

        LEAD(sb.plan_id) OVER (
            PARTITION BY sb.phone_id
            ORDER BY
                sb.subscription_start_date,
                sb.subscription_end_date,
                sb.subscription_id
        ) AS next_plan_id,

        LEAD(sb.plan_name) OVER (
            PARTITION BY sb.phone_id
            ORDER BY
                sb.subscription_start_date,
                sb.subscription_end_date,
                sb.subscription_id
        ) AS next_plan_name,

        LEAD(sb.plan_description) OVER (
            PARTITION BY sb.phone_id
            ORDER BY
                sb.subscription_start_date,
                sb.subscription_end_date,
                sb.subscription_id
        ) AS next_plan_description,

        LEAD(sb.plan_duration) OVER (
            PARTITION BY sb.phone_id
            ORDER BY
                sb.subscription_start_date,
                sb.subscription_end_date,
                sb.subscription_id
        ) AS next_plan_duration,

        LEAD(sb.plan_price) OVER (
            PARTITION BY sb.phone_id
            ORDER BY
                sb.subscription_start_date,
                sb.subscription_end_date,
                sb.subscription_id
        ) AS next_plan_price,

        LEAD(sb.subscription_start_date) OVER (
            PARTITION BY sb.phone_id
            ORDER BY
                sb.subscription_start_date,
                sb.subscription_end_date,
                sb.subscription_id
        ) AS next_subscription_start_date,

        LEAD(sb.subscription_end_date) OVER (
            PARTITION BY sb.phone_id
            ORDER BY
                sb.subscription_start_date,
                sb.subscription_end_date,
                sb.subscription_id
        ) AS next_subscription_end_date

    FROM subscription_base AS sb
),

subscription_outcome AS (
    SELECT
        ss.*,
        db.data_end_date,

        CASE
            WHEN ss.next_subscription_start_date IS NOT NULL
            THEN
                ss.next_subscription_start_date
                - ss.subscription_end_date
        END AS gap_days_after_expiry,

        CASE
            WHEN ss.next_subscription_id IS NOT NULL
            THEN TRUE
            ELSE FALSE
        END AS has_later_subscription_flag,

        /*
          方案轉換只在有後續 subscription 時判斷。
        */
        CASE
            WHEN ss.next_subscription_id IS NOT NULL
             AND ss.next_plan_id = ss.plan_id
            THEN TRUE
            ELSE FALSE
        END AS same_plan_flag,

        CASE
            WHEN ss.next_subscription_id IS NOT NULL
             AND ss.next_plan_id <> ss.plan_id
            THEN TRUE
            ELSE FALSE
        END AS switched_plan_flag,

        CASE
            WHEN ss.next_subscription_id IS NULL
                THEN 'No Later Subscription'

            WHEN ss.next_plan_id = ss.plan_id
                THEN 'Same Plan'

            WHEN ss.next_plan_id <> ss.plan_id
                THEN 'Switched Plan'

            ELSE 'Unclassified'
        END AS plan_transition_status,

        /*
          Lifecycle 定義與 fact_customer_support_impact 相同。
        */
        CASE
            WHEN ss.next_subscription_id IS NOT NULL
             AND ss.next_subscription_start_date
                    <= ss.subscription_end_date + 1
                THEN 'Immediate Renewal'

            WHEN ss.next_subscription_id IS NOT NULL
             AND ss.next_subscription_start_date
                    > ss.subscription_end_date + 1
                THEN 'Returned After Gap'

            WHEN ss.next_subscription_id IS NULL
             AND ss.subscription_end_date
                    <= db.data_end_date
                THEN 'Churn'

            WHEN ss.next_subscription_id IS NULL
             AND ss.subscription_end_date
                    > db.data_end_date
                THEN 'Active at Data End'

            ELSE 'Not Evaluated'
        END AS lifecycle_status,

        CASE
            WHEN ss.next_subscription_id IS NOT NULL
             AND ss.next_subscription_start_date
                    <= ss.subscription_end_date + 1
            THEN TRUE
            ELSE FALSE
        END AS immediate_renewal_flag,

        CASE
            WHEN ss.next_subscription_id IS NOT NULL
             AND ss.next_subscription_start_date
                    > ss.subscription_end_date + 1
            THEN TRUE
            ELSE FALSE
        END AS returned_after_gap_flag,

        CASE
            WHEN ss.next_subscription_id IS NULL
             AND ss.subscription_end_date
                    <= db.data_end_date
            THEN TRUE
            ELSE FALSE
        END AS churn_flag,

        CASE
            WHEN ss.next_subscription_id IS NULL
             AND ss.subscription_end_date
                    > db.data_end_date
            THEN TRUE
            ELSE FALSE
        END AS active_at_data_end_flag,

        /*
          Renewal / Returned / Churn 的共同分母資格。

          已到期的 subscription 才有完整的續訂或流失機會；
          Active at Data End 不進入 lifecycle rate 分母。
        */
        CASE
            WHEN ss.subscription_end_date <= db.data_end_date
            THEN TRUE
            ELSE FALSE
        END AS eligible_outcome_flag

    FROM subscription_sequence AS ss

    CROSS JOIN data_boundary AS db
)

SELECT
    subscription_id,
    phone_id,
    customer_id,

    plan_id,
    plan_name,
    plan_description,
    plan_duration,
    plan_price,

    subscription_start_date,
    subscription_end_date,
    actual_service_days,

    next_subscription_id,
    next_plan_id,
    next_plan_name,
    next_plan_description,
    next_plan_duration,
    next_plan_price,
    next_subscription_start_date,
    next_subscription_end_date,

    gap_days_after_expiry,

    has_later_subscription_flag,
    same_plan_flag,
    switched_plan_flag,
    plan_transition_status,

    lifecycle_status,
    immediate_renewal_flag,
    returned_after_gap_flag,
    churn_flag,
    active_at_data_end_flag,
    eligible_outcome_flag,

    data_end_date

FROM subscription_outcome;