{{ config(materialized='table') }}

WITH retail AS (
    SELECT
        customer_id,
        country,
        MIN(invoice_date)                           AS first_seen,
        SUM(quantity * unit_price)                  AS lifetime_spend,
        COUNT(DISTINCT invoice_no)                  AS order_count,
        COUNT(DISTINCT DATE_TRUNC('month', invoice_date)) AS active_months
    FROM {{ ref('stg_online_retail') }}
    WHERE NOT is_anonymous
      AND transaction_type = 'SALE'
    GROUP BY 1, 2
),

-- Derive segment from actual ERP spend behaviour
segmented AS (
    SELECT
        customer_id,
        country,
        first_seen,
        lifetime_spend,
        order_count,
        active_months,
        CASE
            WHEN lifetime_spend >= 10000            THEN 'VIP'
            WHEN lifetime_spend >= 3000             THEN 'HIGH'
            WHEN lifetime_spend >= 500              THEN 'MID'
            ELSE                                         'LOW'
        END                                         AS segment,
        CASE
            WHEN lifetime_spend >= 10000            THEN 'VIP'
            WHEN lifetime_spend >= 3000             THEN 'HIGH'
            WHEN lifetime_spend >= 500              THEN 'MID'
            ELSE                                         'LOW'
        END                                         AS ltv_band,
        -- Assign churn probability by segment tier
        -- Mirrors Telco dataset churn rates for equivalent spend tiers
        CASE
            WHEN lifetime_spend >= 10000            THEN 0.05
            WHEN lifetime_spend >= 3000             THEN 0.12
            WHEN lifetime_spend >= 500              THEN 0.28
            ELSE                                         0.45
        END                                         AS churn_probability,
        CASE
            WHEN lifetime_spend < 500               THEN TRUE
            ELSE                                         FALSE
        END                                         AS churn_flag
    FROM retail
)

SELECT
    ROW_NUMBER() OVER (ORDER BY customer_id)        AS customer_surrogate_key,
    customer_id,
    country,
    first_seen,
    lifetime_spend,
    order_count,
    active_months,
    segment,
    ltv_band,
    churn_probability,
    churn_flag,
    CURRENT_DATE                                    AS effective_from,
    '9999-12-31'::DATE                              AS effective_to,
    TRUE                                            AS is_current

FROM segmented