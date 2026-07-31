# Star Schema Description
## Dimensions
- dim_date
- dim_customer
- dim_phone
- dim_plan
- dim_csr

## Fact
### Subscription Analytics
**1. fact_subscription_payment**
- Grain: One row represents one subscription and its related payment.
- Source: raw.subscriptions, raw.payments
- Analytical use cases:
    - Total Revenue
    - Paid Subscriptions
    - Revenue by Plan
    - Payment Method Distribution
    - Subscription Start/End Trend
    - Customer/Phone/Plan-level Revenue

**2. fact_subscription_outcome**
- Grain: One row represents one subscription.
- This table is used to analyze the outcome after each subscription ends, such as whether the customer renews immediately, returns after a gap, churns, or remains active as of the data end date. It complements the limitation of fact_subscription_payment, which can only analyze revenue and payments but cannot determine post-subscription behavior. This table is the core fact table for subscription lifecycle analysis.
- Source: raw.subscriptions, raw.phone_number, raw.plans, raw.payments, raw.support_requests
- Analytical use cases:
    - Renewal Rate
    - Churn Rate
    - Return After Gap Rate
    - Active Subscription at Data End
    - Plan Transition Analysis
    - Subscription Lifecycle by Plan / Customer / Phone
    
- Special definitions:
    - **lifecycle_status**:
        - Immediate Renewal: The next subscription for the same phone number starts on the current subscription end date or the following day.
        - Returned After Gap: A later subscription exists for the same phone number, but its start date is later than the day after the current subscription end date, indicating an interruption between subscriptions.
        - Churn: No later subscription exists, and the current subscription end date is less than or equal to data_end_date.
        - Active at Data End: No later subscription exists, but the current subscription end date is still later than data_end_date.
    - **eligible_outcome_flag**: Only expired subscriptions are included in the shared denominator for renewal, return, and churn rates. Active subscriptions should not be counted prematurely as churned or renewed.
    - **plan_transition_status**: No Later Plan, Same Plan, Switch Plan.
    - **next_plan_name**: Indicates how the plan changed in the next subscription.

### Support Analytics
**1. fact_support_request**
- Grain: One row represents one support request.
- Source: raw.support_requests
- This is the cleanest customer support event-level dataset, without mixing in subscription attribution or subsequent lifecycle judgments.
- Analytical use cases:
    - Support Request Volume
    - Request Type Distribution
    - CSR Workload
    - Resolution Time Analysis

**2. fact_customer_support_impact**
- Grain: One row represents one support request, with the subscription attribution on the request date and the subsequent subscription outcome attached.
- This table analyzes the impact of support requests on subsequent subscription outcomes. Because a customer may have multiple phone numbers, a support request cannot always be directly attributed to a specific phone number. Therefore, this table first determines whether the request date can be uniquely mapped to an active subscription, and then further analyzes whether that phone number subsequently renews immediately, returns after a gap, churns, or remains active.
- Source: raw.support_requests, raw.customers, raw.subscriptions, raw.plans, raw.payments
- Analytical use cases:
    - Support Impact on Renewal / Churn / Returned After Gap
    - Request Type vs Lifecycle Outcome
    - CSR / Request Type Resolution Analysis
    - Plan Upgrade / Downgrade after Support
    - Customer Age Group Support Behavior
- Special definitions:
    - **phone_assignment_status**:
        - No Active Subscription: There is no active subscription on the request date.
        - Ambiguous Multiple Active Phones: The same customer has multiple active phone numbers on the request date, so it is not possible to determine which phone number was affected by the support request.
        - Unique Active Subscription: The request date can be uniquely mapped to exactly one phone number and one subscription.
        - Data Issue - Overlapping Subscriptions: There is only one active phone number, but the same phone number has multiple active subscriptions, indicating an abnormal overlap in the data.
    - **attributable_phone_flag**: TRUE only when *active_phone_count = 1* and *active_subscription_count = 1*, meaning the request can be used for subsequent phone-level analysis.
    - **lifecycle_status**: Evaluated only for requests that can be uniquely attributed.
        - Immediate Renewal: The next subscription for the same phone number starts on the current subscription end date or the following day.
        - Returned After Gap: A later subscription exists for the same phone number, but its start date is later than the day after the current subscription end date, indicating an interruption between subscriptions.
        - Churn: No later subscription exists, and the current subscription end date is less than or equal to data_end_date.
        - Active at Data End: No later subscription exists, but the current subscription end date is still later than data_end_date.
    - **plan_change_status**: Plan ranking logic: Basic28 < Basic365 < DataPlus28 < DataPlus365 < Unlimited28 < Unlimited365.
        - Retained Same Plan: The next subscription uses the same plan.
        - Upgrade: The next plan ranks higher than the plan at the time of the request.
        - Downgrade: The next plan ranks lower than the plan at the time of the request.
        - No Later Plan: There is no subsequent subscription.
    - **Age_group_at_request**: Under 18, 18-24, 25-34, 35-44, 45-54, 55-64, 65+, Unknown

**3. customer_request_summary**
- Grain: One row represents one customer.
- This table aggregates support requests from the event level to the customer level. It is used to analyze whether each customer has ever contacted support, how frequently they used support, and the timing of their first and most recent support contact.
- Source: raw.customers, raw.support_requests
- Analytical use cases:
    - Customers with / without Support Contact
    - One-time vs Repeat Support Customers
    - Support Frequency Group Analysis
- Special definitions:
    - support_customer_status:
        - Never Contacted Support: The number of support requests is 0.
        - One-time Support Customer: The number of support requests is 1.
        - Repeat Support Customer: The number of support requests is greater than 1.

    - request_frequency_group:
        - 0: No support records.
        - 1: One support record.
        - 2-3: Two to three support records.
        - 4+: Four or more support records.

**4. phone_subscription_summary**
- Grain: One row represents one phone_id.
- This table aggregates subscription history and support attribution results to the phone-number level. It is used to analyze whether each phone number is currently active, whether it has ever renewed, whether it has ever returned after a gap, and whether it has ever had a uniquely attributable support request. It is suitable for phone-level summary analysis of retention, churn, and support impact.
- Source: raw.phone_number, raw.subscriptions, raw.plans, raw.support_requests, analytics.fact_customer_support_impact
- Analytical use cases:
    - Phone-level Support Attribution
    - Latest Attributed Request Type
- Special definitions:
    - current_phone_status:
        - Never Subscribed: This phone number has no subscriptions.
        - Churn: The end date of the latest subscription is less than or equal to data_end_date.
        - Active at Data End: The latest subscription is still active on data_end_date.
        - Future Subscription: The start date of the latest subscription is later than data_end_date.
    - has_attributed_support_flag: Indicates whether this phone number has ever had a uniquely attributable support request.
    - phone_support_status:
        - No Attributed Support: There are no support requests uniquely attributable to this phone number.
        - One Attributed Request: There is exactly one support request uniquely attributable to this phone number.
        - Multiple Attributed Requests: There are multiple support requests uniquely attributable to this phone number.
    - customer_has_support_flag indicates whether the customer has ever contacted support at the customer level. It does not mean that this specific phone number has contacted support. Phone-level support impact should be based on has_attributed_support_flag.
