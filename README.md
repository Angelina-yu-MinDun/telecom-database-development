# Telecom Database Development

End-to-end relational database and analytics project for **VitaSignal**, a synthetic UK telecommunications provider. The project covers business requirement framing, ERD-based schema design, synthetic operational data generation, PostgreSQL schema design, analytical SQL modeling, and Power BI dashboard development.

## Project Overview

This project simulates the data operations of a telecom company that manages customers, phone numbers, subscription plans, payments, support requests, and customer service representatives.

The goal was to design a realistic relational database from business assumptions, generate linked synthetic data, and use SQL queries to produce practical business insights.

## Key Skills Demonstrated

- Relational database design
- Entity relationship modeling
- Normalization to 3NF
- PostgreSQL schema design and implementation
- Synthetic data generation with business rules
- SQL querying for business insights
- Data validation and referential integrity checks
- Power BI dashboard development

## Dataset Scope

The full delivered dataset contains:

- Customers: 2,519 records
- Phone numbers: 3,381 records
- Plans: 6 records
- Subscriptions: 10,342 records
- Payments: 10,342 records
- Support requests: 2,940 records
- Customer service representatives: 15 records

The complete synthetic CSV dataset is included in [`data/`](data/). The data is synthetic.

## Power BI Dashboard

An interactive Power BI dashboard was developed to present the main customer, subscription, revenue, and support-service insights from this project.

- [View the interactive Power BI report](https://app.powerbi.com/view?r=eyJrIjoiY2NiNTM0NmQtMmIzMi00MDhkLWE4YWMtYzg2ZWZjMDhlOTdhIiwidCI6ImFjMGUxYjNmLTQ3NmEtNGM1MC05ZTdkLTcyMmI0ODMyYjk5MSJ9)
- [`powerbi/Telecom Dashboard.pbix`](powerbi/Telecom%20Dashboard.pbix): Power BI report file

## Database Entities

- `customers`: Customer profile and registration information
- `phone_number`: Phone numbers owned by customers
- `plans`: Telecom subscription plan catalogue
- `subscriptions`: Plan subscription cycles by customer and phone number
- `payments`: Payment transactions linked to subscriptions
- `support_requests`: Customer support interactions and resolution timing
- `customer_service_rep`: CSR profile and employment type


## Business Questions Answered

The SQL analysis focuses on questions relevant to telecom operations:

1. How did customer registrations change by age group between 2023 and 2024?
2. Which plans were most popular in 2024, and which generated the most revenue?
3. Which payment methods were preferred by each age group in 2024?
4. Which support request types were most common, and how long did they take to resolve?
5. How was support workload split between full-time and part-time CSRs?

## Selected Findings

- Customer registrations increased from 770 in 2022 to 812 in 2023 and 915 in 2024.
- 365-day subscription plans generated the strongest revenue in the synthetic dataset.
- `DataPlus365` and `Unlimited365` were the highest revenue-contributing plans.
- `Service & Account Management` and `General Inquiry` were the most common support request types.
- Average support resolution time ranged from about 1 hour for general inquiries to about 88 hours for technical support.

## Repository Structure

```text
.
├── data/
│   ├── csr_table.csv
│   ├── customers.csv
│   ├── payments.csv
│   ├── phone.csv
│   ├── plans.csv
│   ├── subscriptions.csv
│   └── support_requests.csv
├── docs/
│   ├── assumptions.md
│   ├── data_dictionary.md
│   ├── ERD.md
│   └── validation_summary.md
├── powerbi/
│   └── Telecom Dashboard.pbix
├── sql/
│   ├── 01. database schemas table preparation.sql
│   ├── 02. validation_queries.sql
│   ├── 03. analytics_dimensions_analytics.sql
│   ├── 04.01 analytics_fact_support_analytics/
│   │   ├── 01_fact_support_request.sql
│   │   ├── 02_fact_customer_support_impact.sql
│   │   ├── 03_customer_request_summary.sql
│   │   └── 04_phone_subscription_summary.sql
│   ├── 04.02_analytics_fact_subscription_analytics/
│   │   ├── 01_fact_subscription_payment.sql
│   │   └── 02_fact_subscription_outcome.sql
│   ├── Star Schema Description.md
│   └── Star Schema Description_EN.md
└── README.md
```

## Files

- [`sql/01. database schemas table preparation.sql`](sql/01.%20database%20schemas%20table%20preparation.sql): PostgreSQL database, schema, and raw table definitions
- [`sql/02. validation_queries.sql`](sql/02.%20validation_queries.sql): Data quality, relationship, and business-rule validation queries
- [`sql/03. analytics_dimensions_analytics.sql`](sql/03.%20analytics_dimensions_analytics.sql): Analytical dimension views for BI reporting
- [`sql/04.01 analytics_fact_support_analytics/`](sql/04.01%20analytics_fact_support_analytics): Support-service analytical fact views
- [`sql/04.02_analytics_fact_subscription_analytics/`](sql/04.02_analytics_fact_subscription_analytics): Subscription, payment, and outcome analytical fact views
- [`sql/Star Schema Description_EN.md`](sql/Star%20Schema%20Description_EN.md): English star schema documentation
- [`sql/Star Schema Description.md`](sql/Star%20Schema%20Description.md): Chinese star schema documentation
- [`docs/ERD.md`](docs/ERD.md): Entity relationship diagram in Mermaid format
- [`docs/data_dictionary.md`](docs/data_dictionary.md): Table and column definitions
- [`docs/assumptions.md`](docs/assumptions.md): Synthetic data generation assumptions
- [`docs/validation_summary.md`](docs/validation_summary.md): Dataset scale and relationship validation summary
- [`data`](data): Complete synthetic CSV dataset
- [`powerbi/Telecom Dashboard.pbix`](powerbi/Telecom%20Dashboard.pbix): Power BI dashboard file
