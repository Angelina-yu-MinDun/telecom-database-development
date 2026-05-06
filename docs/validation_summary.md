# Validation Summary

This document summarizes the delivered dataset scale and relationship checks performed before preparing the public portfolio version.

## Delivered Dataset Scale

| Table | Records |
| --- | ---: |
| Customers | 2,519 |
| Phone numbers | 3,381 |
| Plans | 6 |
| Subscriptions | 10,342 |
| Payments | 10,342 |
| Support requests | 2,940 |
| Customer service representatives | 15 |

Total records across the delivered CSV files: **29,545**.

## Relationship Checks

The following checks returned zero missing links in the delivered CSV dataset:

- Subscriptions without a matching customer: 0
- Subscriptions without a matching phone number: 0
- Subscriptions without a matching plan: 0
- Payments without a matching subscription: 0
- Support requests without a matching customer: 0
- Support requests without a matching CSR: 0

## Selected Distribution Checks

Customer registrations by year:

| Year | Registrations |
| --- | ---: |
| 2022 | 770 |
| 2023 | 812 |
| 2024 | 915 |
| 2025 | 22 |

Support request volume by type:

| Request type | Requests |
| --- | ---: |
| Service & Account Management | 988 |
| General Inquiry | 762 |
| Technical Support | 584 |
| Security & Fraud | 391 |
| Billing & Payments | 215 |

Average support resolution time:

| Request type | Average hours |
| --- | ---: |
| General Inquiry | 1.04 |
| Service & Account Management | 3.34 |
| Billing & Payments | 12.30 |
| Security & Fraud | 25.54 |
| Technical Support | 88.10 |

## Portfolio Interpretation

The validation checks support the portfolio claim that the project was not only a data generation task. The dataset was designed with relational consistency, business rules, and analytical use cases in mind.
