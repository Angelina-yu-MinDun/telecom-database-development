# Telecom Database Development

End-to-end relational database and analytics project for **VitaSignal**, a synthetic UK telecommunications provider. The project covers business requirement framing, ERD-based schema design, synthetic operational data generation, SQLite implementation, SQL analysis, and business reporting.

## Project Overview

This project simulates the data operations of a telecom company that manages customers, phone numbers, subscription plans, payments, support requests, and customer service representatives.

The goal was to design a realistic relational database from business assumptions, generate linked synthetic data, and use SQL queries to produce practical business insights.

## Key Skills Demonstrated

- Relational database design
- Entity relationship modeling
- Normalization to 3NF
- SQLite schema implementation
- Synthetic data generation with business rules
- SQL querying for business insights
- Data validation and referential integrity checks
- Portfolio-ready data storytelling

## Dataset Scope

The full delivered dataset contains:

- Customers: 2,519 records
- Phone numbers: 3,381 records
- Plans: 6 records
- Subscriptions: 10,342 records
- Payments: 10,342 records
- Support requests: 2,940 records
- Customer service representatives: 15 records

Only small sample CSV files are included in this public portfolio version. The data is synthetic and was generated for educational and portfolio demonstration purposes.

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
telecom-database-development/
  README.md
  data/
    sample/
      *_sample.csv
  docs/
    assumptions.md
    data_dictionary.md
    validation_summary.md
  sql/
    schema.sql
    insight_queries.sql
  visuals/
    dashboard_screenshots/
```

## Files

- [`sql/schema.sql`](sql/schema.sql): Clean SQLite DDL for the relational schema
- [`sql/insight_queries.sql`](sql/insight_queries.sql): SQL queries for the main business questions
- [`docs/data_dictionary.md`](docs/data_dictionary.md): Table and column definitions
- [`docs/assumptions.md`](docs/assumptions.md): Synthetic data generation assumptions
- [`docs/validation_summary.md`](docs/validation_summary.md): Dataset scale and relationship validation summary
- [`data/sample`](data/sample): Small public sample of the synthetic CSV tables

## Notes on Public Version

This repository is a cleaned portfolio version. It excludes the original coursework report, presentation video, and full dataset. The public version focuses on reusable technical assets: schema, queries, documentation, and sample data.

The project was originally completed as a group academic assignment. This repository highlights the database design, data generation logic, SQL analysis, and portfolio presentation work relevant to data analytics and data management roles.
