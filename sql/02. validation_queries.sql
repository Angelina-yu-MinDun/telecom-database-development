-- =========================================================
-- CUSTOMERS TABLE VALIDATION
-- =========================================================
SELECT COUNT(*) AS customer_count
FROM raw.customers;

SELECT *
FROM raw.customers
ORDER BY customer_id
LIMIT 10

-- 1. Check total row count and unique customer IDs

SELECT
    COUNT(*) AS total_rows,
	COUNT(DISTINCT customer_id) AS unique_customer_ids
FROM raw.customers;


-- 2. Check required columns for NULL values
SELECT
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS null_customer_id,
    COUNT(*) FILTER (WHERE registration_date IS NULL) AS null_registration_date,
    COUNT(*) FILTER (WHERE date_of_birth IS NULL) AS null_date_of_birth,
    COUNT(*) FILTER (WHERE name IS NULL) AS null_name,
    COUNT(*) FILTER (WHERE email IS NULL) AS null_email,
    COUNT(*) FILTER (WHERE address IS NULL) AS null_address
FROM raw.customers;


-- 3. Check duplicate email addresses
SELECT
    email,
    COUNT(*) AS customer_count
FROM raw.customers
GROUP BY email
HAVING COUNT(*) > 1
ORDER BY customer_count DESC, email;


-- 4. Check impossible date relationships
SELECT
    customer_id,
    date_of_birth,
    registration_date
FROM raw.customers
WHERE registration_date < date_of_birth;


-- 5. Check customers younger than 16 at registration
SELECT
    customer_id,
    date_of_birth,
    registration_date,
    EXTRACT(
        YEAR FROM AGE(registration_date, date_of_birth)
    ) AS age_at_registration
FROM raw.customers
WHERE AGE(registration_date, date_of_birth) < INTERVAL '16 years';


-- =========================================================
-- PLANS TABLE VALIDATION
-- =========================================================
SELECT *
FROM information_schema.columns
WHERE table_schema = 'raw'
  AND table_name = 'plans'
ORDER BY ordinal_position;

SELECT *
FROM raw.plans;

-- =========================================================
-- PHONE_NUMBER TABLE VALIDATION
-- =========================================================

-- 1. Check total rows and unique IDs
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT phone_id) AS unique_phone_ids,
    COUNT(DISTINCT phone_number) AS unique_phone_numbers
FROM raw.phone_number;


-- 2. Check NULL values
SELECT
    COUNT(*) FILTER (WHERE phone_id IS NULL) AS null_phone_id,
    COUNT(*) FILTER (WHERE customer_id IS NULL) AS null_customer_id,
    COUNT(*) FILTER (WHERE phone_number IS NULL) AS null_phone_number,
    COUNT(*) FILTER (WHERE activation_date IS NULL) AS null_activation_date
FROM raw.phone_number;


-- 3. Check duplicate phone numbers
SELECT
    phone_number,
    COUNT(*) AS duplicate_count
FROM raw.phone_number
GROUP BY phone_number
HAVING COUNT(*) > 1;


-- 4. Check phone records without a matching customer
SELECT
    p.phone_id,
    p.customer_id
FROM raw.phone_number AS p
LEFT JOIN raw.customers AS c
    ON p.customer_id = c.customer_id
WHERE c.customer_id IS NULL;


-- 5. Check phone activation before customer registration
SELECT
    p.phone_id,
    p.customer_id,
    c.registration_date,
    p.activation_date
FROM raw.phone_number AS p
JOIN raw.customers AS c
    ON p.customer_id = c.customer_id
WHERE p.activation_date < c.registration_date;


-- 6. Number of phones owned by each customer
SELECT
    customer_id,
    COUNT(*) AS phone_count
FROM raw.phone_number
GROUP BY customer_id
ORDER BY phone_count DESC, customer_id;

/*Summary*/
SELECT
    phone_count,
    COUNT(*) AS customer_count
FROM (
    SELECT
        customer_id,
        COUNT(*) AS phone_count
    FROM raw.phone_number
    GROUP BY customer_id
) AS customer_phone_counts
GROUP BY phone_count
ORDER BY phone_count;

-- =========================================================
-- Subscriptions VALIDATION
-- =========================================================
SELECT
    column_name,
    data_type,
    character_maximum_length
FROM information_schema.columns
WHERE table_schema = 'raw'
  AND table_name = 'subscriptions'
ORDER BY ordinal_position;

-- 1. Row count and unique subscription IDs
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT subscription_id) AS unique_subscription_ids
FROM raw.subscriptions;

-- 2. NULL checks
SELECT
	COUNT(*) fILTER(WHERE subscription_id is NULL) AS null_subscription_id,
	COUNT(*) fILTER(WHERE customer_id is NULL) AS null_customer_id,
	COUNT(*) fILTER(WHERE phone_id is NULL) AS null_phone_id,
	COUNT(*) fILTER(WHERE plan_id is NULL) AS null_plan_id,
	COUNT(*) fILTER(WHERE start_date is NULL) AS null_start_date,
	COUNT(*) fILTER(WHERE end_date is NULL) AS null_end_date
FROM raw.subscriptions;

-- 3. Invalid date ranges
SELECT *
FROM raw.subscriptions
WHERE start_date >end_date;

-- 4. Subscriptions without matching customers
SELECT s.customer_id, c.customer_id
FROM raw.subscriptions as s
LEFT JOIN raw.customers as c
ON s.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- 5. Subscriptions without matching phone numbers
SELECT
    s.subscription_id,
    s.phone_id
FROM raw.subscriptions AS s
LEFT JOIN raw.phone_number AS p
    ON s.phone_id = p.phone_id
WHERE p.phone_id IS NULL;


-- 6. Subscriptions without matching plans
SELECT
    s.subscription_id,
    s.plan_id
FROM raw.subscriptions AS s
LEFT JOIN raw.plans AS p
    ON s.plan_id = p.plan_id
WHERE p.plan_id IS NULL;


-- 7. Check that the phone belongs to the same customer
SELECT
    s.subscription_id,
    s.customer_id AS subscription_customer,
    p.customer_id AS phone_owner,
    s.phone_id
FROM raw.subscriptions AS s
JOIN raw.phone_number AS p
    ON s.phone_id = p.phone_id
WHERE s.customer_id <> p.customer_id;

-- =========================================================
-- Payment VALIDATION
-- =========================================================
-- 1. Check Row count and unique Payment IDs
SELECT 
	count(*) AS total_rows,
	count(payment_id) AS unique_payments,
	count(subscription_id) AS unique_subscriptions
FROM raw.payments;

-- 2. NULL checks
SELECT
	COUNT(*) fILTER(WHERE payment_id is NULL) AS null_payment_id,
	COUNT(*) fILTER(WHERE subscription_id is NULL) AS null_subscription_id,
	COUNT(*) fILTER(WHERE customer_id is NULL) AS null_customer_id,
	COUNT(*) fILTER(WHERE payment_date is NULL) AS null_payment_date,
	COUNT(*) fILTER(WHERE payment_method is NULL) AS null_payment_method,
	COUNT(*) fILTER(WHERE amount is NULL) AS null_amount
FROM raw.payments;

-- 3. Duplicate Payment_ID checks
SELECT 
	payment_id,
	Count(*) as duplicate_count
FROM raw.payments
GROUP BY payment_id
HAVING COUNT(*) > 1;

-- 3. Duplicate subscription_ID checks
SELECT 
	subscription_id,
	Count(payment_id) as duplicate_count
FROM raw.payments
GROUP BY subscription_id
HAVING COUNT(payment_id) > 1;

-- 4. payment methods
SELECT *
FROM raw.payments
WHERE payment_method NOT IN ('Credit Card','Debit Card','Bank Transfer','Cash','PayPal')

-- 5. payment amounts
SELECT *
FROM raw.payments
WHERE amount <= 0;

SELECT
	MAX(amount),
	MIN(amount),
	AVG(amount)
FROM raw.payments

-- 6. Payments without a matching subscription
SELECT p.payment_id, p.subscription_id
FROM raw.payments AS p LEFT JOIN raw.subscriptions AS s
ON p.subscription_id = s.subscription_id
WHERE s.subscription_id is NULL;

-- 7. Payments without a matching customer
SELECT p.payment_id, p.customer_id
FROM raw.payments AS p LEFT JOIN raw.customers AS c
ON p.customer_id = c.customer_id
WHERE c.customer_id is NULL;

-- 8. Payment customer does not match subscription customer
SELECT
    p.payment_id,
    p.subscription_id,
    p.customer_id AS payment_customer_id,
    s.customer_id AS subscription_customer_id
FROM raw.payments AS p
JOIN raw.subscriptions AS s
    ON p.subscription_id = s.subscription_id
WHERE p.customer_id <> s.customer_id;

-- 9. Payment Date
SELECT 
	p.payment_id,
	p.payment_method,
	s.subscription_id,
	p.payment_date,
	s.start_date
FROM raw.payments AS p
JOIN raw.subscriptions AS s
    ON p.subscription_id = s.subscription_id
WHERE p.payment_date < s.start_date;

-- 10.payment amount
SELECT 
	p.payment_id,
	s.subscription_id,
	pl.plan_id,
	p.amount, 
	pl.price
FROM raw.payments AS p
JOIN raw.subscriptions AS s
    ON p.subscription_id = s.subscription_id
JOIN raw.plans AS pl
	 ON s.plan_id = pl.plan_id
WHERE p.amount <> pl.price;

-- =========================================================
-- CSR VALIDATION
-- =========================================================
SELECT *
FROM raw.customer_service_rep

SELECT 
	DISTINCT (employment_type),
	count(csr_id) AS total_csr
FROM raw.customer_service_rep
GROUP BY employment_type

SELECT csr_id,count(*) AS duplicate_count
FROM raw.customer_service_rep
GROUP BY csr_id
HAVING COUNT(*) > 1

-- =========================================================
-- Request VALIDATION
-- =========================================================
SELECT count(*)
FROM raw.support_requests

SELECT 
	DISTINCT (request_type),
	count(request_id) AS total_request
FROM raw.support_requests
GROUP BY request_type
ORDER by total_request DESC

SELECT request_id, open_time, closed_time
FROM raw.support_requests
WHERE closed_time<open_time;



