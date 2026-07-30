-- =========================================================
-- View Name : analytics.fact_subscription_payment
-- Grain     : One row per subscription cycle and its payment
-- Purpose   : Support subscription, payment, and revenue analysis
-- Sources   : raw.subscriptions, raw.payments
-- Used By   : Executive, Customer Behaviour, Revenue Dashboard
-- =========================================================

CREATE OR REPLACE VIEW analytics.fact_subscription_payment AS

SELECT
    s.subscription_id,
    p.payment_id,
    s.customer_id,
    s.phone_id,
    s.plan_id,
    s.start_date,
    s.end_date,
    p.payment_date,
    p.payment_method,
    p.amount

FROM raw.subscriptions AS s
LEFT JOIN raw.payments AS p
    ON s.subscription_id = p.subscription_id;
