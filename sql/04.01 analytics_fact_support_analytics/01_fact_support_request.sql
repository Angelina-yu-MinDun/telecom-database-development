-- =========================================================
-- View Name : analytics.fact_support_request
-- Grain     : One row per support request
-- Purpose   : Support case volume and resolution analysis
-- Source    : raw.support_requests
-- Used By   : Executive Overview, Customer Service Dashboard
-- =========================================================
CREATE OR REPLACE VIEW analytics.fact_support_request AS

SELECT
	sr.request_id,
	sr.customer_id,
	sr.open_time,
	sr.closed_time,
	sr.request_type,
	sr.csr_id,
    sr.open_time::DATE AS open_date,
    sr.closed_time::DATE AS closed_date

FROM raw.support_requests AS sr;