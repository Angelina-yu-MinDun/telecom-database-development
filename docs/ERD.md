# Entity Relationship Diagram

This ERD describes the relational structure used for the VitaSignal telecom database project.

```mermaid
erDiagram
    CUSTOMERS ||--o{ PHONE_NUMBER : owns
    CUSTOMERS ||--o{ SUBSCRIPTIONS : has
    PHONE_NUMBER ||--o{ SUBSCRIPTIONS : uses
    PLANS ||--o{ SUBSCRIPTIONS : includes
    SUBSCRIPTIONS ||--|| PAYMENTS : paid_by
    CUSTOMERS ||--o{ PAYMENTS : makes
    CUSTOMERS ||--o{ SUPPORT_REQUESTS : submits
    CUSTOMER_SERVICE_REP ||--o{ SUPPORT_REQUESTS : handles

    CUSTOMERS {
        TEXT customer_id PK
        TEXT registration_date
        TEXT date_of_birth
        TEXT name
        TEXT email
        TEXT address
    }

    PHONE_NUMBER {
        TEXT phone_id PK
        TEXT customer_id FK
        TEXT phone_number
        TEXT activation_date
    }

    PLANS {
        TEXT plan_id PK
        TEXT plan_name
        TEXT plan_description
        INTEGER plan_duration
        REAL price
    }

    SUBSCRIPTIONS {
        TEXT subscription_id PK
        TEXT customer_id FK
        TEXT phone_id FK
        TEXT plan_id FK
        TEXT start_date
        TEXT end_date
    }

    PAYMENTS {
        TEXT payment_id PK
        TEXT subscription_id FK
        TEXT customer_id FK
        TEXT payment_date
        TEXT payment_method
        REAL amount
    }

    SUPPORT_REQUESTS {
        TEXT request_id PK
        TEXT customer_id FK
        TEXT open_time
        TEXT closed_time
        TEXT request_type
        TEXT csr_id FK
    }

    CUSTOMER_SERVICE_REP {
        TEXT csr_id PK
        TEXT csr_name
        TEXT employment_type
    }
```

## Relationship Summary

- One customer can own multiple phone numbers.
- One customer can have multiple subscriptions.
- One phone number can have multiple subscription cycles.
- One plan can be used by many subscriptions.
- Each subscription has one payment record.
- One customer can make multiple payments.
- One customer can submit multiple support requests.
- One customer service representative can handle multiple support requests.
