# Data Dictionary

## customers

Customer account profile and registration information.

| Column | Description |
| --- | --- |
| `customer_id` | Unique customer identifier |
| `registration_date` | Date when the customer registered |
| `date_of_birth` | Customer date of birth |
| `name` | Synthetic customer name |
| `email` | Synthetic customer email |
| `address` | Synthetic UK-style address |

## phone_number

Phone numbers owned by customers. A customer can own more than one phone number.

| Column | Description |
| --- | --- |
| `phone_id` | Unique phone record identifier |
| `customer_id` | Customer who owns the phone number |
| `phone_number` | Synthetic UK-style mobile number |
| `activation_date` | Date when the phone number was activated |

## plans

Subscription plan catalogue.

| Column | Description |
| --- | --- |
| `plan_id` | Unique plan identifier |
| `plan_name` | Plan name |
| `plan_description` | Plan benefits and allowance |
| `plan_duration` | Subscription duration in days |
| `price` | Subscription price |

## subscriptions

Subscription periods linked to customers, phone numbers, and plans.

| Column | Description |
| --- | --- |
| `subscription_id` | Unique subscription identifier |
| `customer_id` | Customer linked to the subscription |
| `phone_id` | Phone number linked to the subscription |
| `plan_id` | Plan selected for the subscription |
| `start_date` | Subscription start date |
| `end_date` | Subscription end date |

## payments

Payment transactions linked to subscriptions.

| Column | Description |
| --- | --- |
| `payment_id` | Unique payment identifier |
| `subscription_id` | Subscription paid by this transaction |
| `customer_id` | Customer who made the payment |
| `payment_date` | Date when the payment was made |
| `payment_method` | Payment channel |
| `amount` | Payment amount |

## customer_service_rep

Customer service representative profile.

| Column | Description |
| --- | --- |
| `csr_id` | Unique CSR identifier |
| `csr_name` | Synthetic CSR name |
| `employment_type` | Full-time or part-time employment status |

## support_requests

Customer support cases submitted in 2024.

| Column | Description |
| --- | --- |
| `request_id` | Unique support request identifier |
| `customer_id` | Customer who submitted the request |
| `open_time` | Request opening timestamp |
| `closed_time` | Request closing timestamp |
| `request_type` | Category of support request |
| `csr_id` | CSR assigned to the request |
