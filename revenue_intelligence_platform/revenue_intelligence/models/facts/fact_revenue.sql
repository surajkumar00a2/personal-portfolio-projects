{{ config(materialized='table') }}

WITH monthly AS (
    SELECT
        customer_surrogate_key,
        DATE_TRUNC('month', invoice_date)           AS revenue_month,
        TO_CHAR(
            DATE_TRUNC('month', invoice_date),
            'YYYYMMDD'
        )::INT                                      AS date_key,
        SUM(line_revenue)                           AS gross_revenue,
        SUM(net_revenue)                            AS net_revenue,
        SUM(net_revenue)                            AS mrr,
        SUM(net_revenue) * 12                       AS arr,
        AVG(net_revenue)                            AS arpu
    FROM {{ ref('fact_invoice') }}
    WHERE transaction_type = 'SALE'
      AND customer_surrogate_key IS NOT NULL
    GROUP BY 1, 2, 3
),

-- Assign churn probability by segment since ERP/CRM IDs don't overlap
-- This mirrors real-world enrichment by account tier
segment_churn AS (
    SELECT
        customer_segment                            AS seg,
        AVG(churn_probability)                      AS avg_churn_probability
    FROM {{ ref('stg_telco_churn') }}
    GROUP BY 1
),

-- Map segment churn rates to ERP customers via dim_customer segment field
customer_churn AS (
    SELECT
        dc.customer_surrogate_key,
        dc.segment,
        COALESCE(sc.avg_churn_probability, 0.10)    AS churn_probability
    FROM gold.dim_customer dc
    LEFT JOIN segment_churn sc
        ON dc.segment = sc.seg
    WHERE dc.is_current = TRUE
)

SELECT
    ROW_NUMBER() OVER (
        ORDER BY m.revenue_month, m.customer_surrogate_key
    )                                               AS revenue_key,
    m.customer_surrogate_key,
    m.date_key,
    m.revenue_month,
    m.gross_revenue,
    m.net_revenue,
    m.mrr,
    m.arr,
    m.arpu,
    cc.churn_probability,
    cc.segment,
    -- Surrogate key from dim_contract — NULL is fine, segment drives churn
    NULL::INT                                       AS contract_surrogate_key

FROM monthly m
LEFT JOIN customer_churn cc
    ON m.customer_surrogate_key = cc.customer_surrogate_key