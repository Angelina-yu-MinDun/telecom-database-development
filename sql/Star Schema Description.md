# Star Schema Description
## Dimensions
- dim_date
- dim_customer
- dim_phone
- dim_plan
- dim_csr

## Fact
### Subscription analytics
**1. fact_subscription_payment**
- Grain：一列代表「一筆 subscription 及其 payment」
- 來源：raw.subscriptions、raw.payments
- 分析用處：
    - Total Revenue
    - Paid Subscriptions
    - Revenue by Plan
    - Payment Method Distribution
    - Subscription start/end trend
    - Customer/Phone/Plan level Revenue

**2. fact_subscription_outcome**
- Grain：一列代表「一筆subscription」
- 此表用來分析每一筆 subscription 結束後的結果，例如是否立即續訂、隔一段時間後回流、流失，或在資料截止日仍有效；它補足 fact_subscription_payment 只能看收入與付款、無法判斷訂閱後續行為的限制，是訂閱生命週期分析的核心 fact。
- 來源：raw.subscriptions、raw.phone_number、raw.plans、raw.payments、raw.support_requests
- 分析用處：
    - Renewal Rate
    - Churn Rate
    - Return After Gap Rate
    - Active Subscription at Data End
    - Plan Transition Analysis
    - Subscription Lifecycle by Plan / Customer / Phone
    
- 特殊定義說明：
    - **lifecycle_status**：
        - Immediate Renewal：同一門號的下一筆 subscription 在本期結束日當天或隔天開始。
        - Returned After Gap：同一門號之後有下一筆 subscription，但下一筆開始日晚於本期結束日隔天，表示中間有中斷。
        - Churn：沒有下一筆 subscription，且本期結束日已小於或等於 data_end_date。
        - Active at Data End：沒有下一筆 subscription，但本期結束日仍晚於 data_end_date。
    - **eligible_outcome_flag**：只有已到期的 subscription 才進入續訂、回流、流失率的共同分母；仍有效的 subscription 不應被提前算入流失或續訂率。
    - **plan_transition_status**：No Later Plan、Same Plan、Switch Plan。
    - **next_plan_name**：可以知道方案轉換變化。

### Support analytics
**1. fact_support_request**
- Grain：一列代表「一筆 support request」。
- 來源：raw.support_requests
- 最乾淨的客服事件層級資料，不混入訂閱歸因或後續生命週期判斷。
- 分析用處：
    - Support Request Volume
    - Request Type Distribution
    - CSR Workload
    - Resolution Time Analysis

**2. fact_customer_support_impact**
- Grain：一列代表一筆 support request，並附帶該 request 當天的訂閱歸因與後續訂閱結果。
- 分析客服 request 對訂閱後續結果的影響。因為一個顧客可能有多支門號，客服 request 不一定能直接歸因到某一支 phone，因此此表先判斷 request 當天是否能唯一對應到有效 subscription，再進一步分析該門號後續是否立即續訂、回流、流失或維持有效。
- 來源：raw.support_requests、raw.customers、raw.subscriptions、raw.plans、raw.payments
- 分析用處：
    - Support Impact on Renewal / Churn / Returned After Gap
    - Request Type vs Lifecycle Outcome
    - CSR / Request Type Resolution Analysis
    - Plan Upgrade / Downgrade after Support
    - Customer Age Group Support Behavior
- 特殊定義說明：
    - **phone_assignment_status**：
        - No Active Subscription：request 當天沒有任何有效 subscription。
        - Ambiguous Multiple Active Phones：request 當天同一顧客有多支有效門號，無法判斷是哪支門號受到客服影響。
        - Unique Active Subscription：request 當天剛好能唯一對應到一支門號與一筆 subscription。
        - Data Issue - Overlapping Subscriptions：只有一支有效門號，但同一門號有多筆有效 subscription，代表資料重疊異常。
    - **attributable_phone_flag**：只有 *active_phone_count = 1* 且 *active_subscription_count = 1* 時為 TRUE，代表該 request 可以被用於門號後續分析。
    - **lifecycle_status**：只針對可唯一歸因的 request 進行判斷
        - Immediate Renewal：同一門號的下一筆 subscription 在本期結束日當天或隔天開始。
        - Returned After Gap：同一門號之後有下一筆 subscription，但下一筆開始日晚於本期結束日隔天，表示中間有中斷。
        - Churn：沒有下一筆 subscription，且本期結束日已小於或等於 data_end_date。
        - Active at Data End：沒有下一筆 subscription，但本期結束日仍晚於 data_end_date。
    - **plan_change_status**：方案排序邏輯：Basic28 < Basic365 < DataPlus28 < DataPlus365 < Unlimited28 < Unlimited365。
        - Retained Same Plan：下一筆訂閱方案相同。
        - Upgrade：下一筆方案排序高於 request 當下方案。
        - Downgrade：下一筆方案排序低於 request 當下方案。
        - No Later Plan：沒有後續訂閱。
    - **Age_group_at_request**：Under 18、18-24、25-34、35-44、45-54、55-64、65+、Unknown

**3. customer_request_summary**
- Grain：一列代表一個 customer。
- 將客服 request 從事件層級彙總到顧客層級，用來分析每位顧客是否曾使用客服、使用頻率，以及首次與最近一次客服接觸時間。
- 來源：raw.customers、raw.support_requests
- 分析用處：
    - Customers with / without Support Contact
    - One-time vs Repeat Support Customers
    - Support Frequency Group Analysis
- 特殊定義說明：
    - support_customer_status：
        - Never Contacted Support：客服 request 數為 0。
        - One-time Support Customer：客服 request 數為 1。
        - Repeat Support Customer：客服 request 數大於 1。

    - request_frequency_group：
        - 0：沒有客服紀錄。
        - 1：一次客服紀錄。
        - 2-3：二至三次客服紀錄。
        - 4+：四次以上客服紀錄。

**4. phone_subscription_summary**
- Grain：一列代表一個 phone_id。
- 將訂閱歷史與客服歸因結果彙總到門號層級，用來分析每支門號目前是否有效、是否曾續訂、是否曾回流、是否曾有可唯一歸因的客服 request。它適合做門號層級的留存、流失與客服影響摘要分析。
- 來源：raw.phone_number、raw.subscriptions、raw.plans、raw.support_requests、analytics.fact_customer_support_impact
- 分析用處：
    - Phone-level Support Attribution
    - Latest Attributed Request Type
- 特殊定義說明：
    - current_phone_status：
        - Never Subscribed：此門號沒有任何 subscription。
        - Churn：最新一筆 subscription 的結束日小於或等於 data_end_date。
        - Active at Data End：最新一筆 subscription 在 data_end_date 當天仍有效。
        - Future Subscription：最新一筆 subscription 開始日晚於 data_end_date。
    - has_attributed_support_flag：此門號是否曾有可唯一歸因的客服 request。
    - phone_support_status：
        - No Attributed Support：沒有任何可唯一歸因到此門號的客服 request。
        - One Attributed Request：剛好一筆可唯一歸因的客服 request。
        - Multiple Attributed Requests：多筆可唯一歸因的客服 request。
    - customer_has_support_flag 是顧客層級是否曾詢問客服，不等於該門號曾詢問客服；門號層級客服影響應以 has_attributed_support_flag 為準。
