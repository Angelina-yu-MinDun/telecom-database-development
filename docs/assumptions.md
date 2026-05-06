# Synthetic Data Assumptions

The dataset is fully synthetic. It was generated to simulate realistic telecom operations while preserving clear relational links across tables.

## Business Context

VitaSignal is a synthetic UK telecommunications provider offering electronic SIM services through 28-day and 365-day plans. The business process includes customer registration, phone number activation, plan subscription, payment, and customer support.

## Customer Generation

- Customer registrations cover January 2022 to February 2025.
- Registration volume was designed to grow over time, with higher registrations in 2024 than in 2022 and 2023.
- Customers are at least 16 years old at registration.
- Customers are generated with UK-style addresses and synthetic contact details.
- Customers can own one to three phone numbers.
- Additional phone numbers are usually activated after the first phone number.

## Plan Design

The plan catalogue contains six plans:

- `Basic28`: 28-day basic data plan
- `Basic365`: 365-day basic data plan
- `DataPlus28`: 28-day mid-tier data plan
- `DataPlus365`: 365-day mid-tier data plan
- `Unlimited28`: 28-day unlimited data plan
- `Unlimited365`: 365-day unlimited data plan

365-day plans are designed to contribute strongly to revenue because of their higher transaction value.

## Subscription Logic

- Each subscription links one customer, one phone number, and one plan.
- First subscriptions align with phone activation.
- Renewals follow the selected plan duration.
- Plan changes generally move customers toward larger or longer-term plans.
- The synthetic subscription logic supports repeated subscription cycles across multiple years.

## Payment Logic

- Each subscription has one linked payment.
- Payment method options include credit card, debit card, bank transfer, cash, and PayPal.
- Customer age influences payment method preference.
- Most customers keep the same payment method across transactions, while a smaller share changes method.
- Cash payments may occur slightly before the subscription start date.

## Support Request Logic

- Support requests are generated only for customers with active subscriptions in 2024.
- Request categories include service and account management, general inquiry, technical support, security and fraud, and billing and payments.
- Request volume is higher near the beginning and end of each month.
- Resolution time varies by request type:
  - General inquiries are usually resolved fastest.
  - Technical support cases usually take longest.
- Part-time CSRs are more likely to handle general inquiry and account-management requests.
- Full-time CSRs are more likely to handle technical, billing, security, and fraud-related requests.

## Public Portfolio Limitation

This public version includes sample data only. The full dataset, original coursework report, and presentation video are excluded from the repository to keep the GitHub version focused, reusable, and suitable for portfolio review.
