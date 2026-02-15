{{ config(materialized='table') }}

WITH monthly AS (
    SELECT
        customer_surrogate_key,
        DATE_TRUNC('month', invoice_date) AS revenue_month,
        TO_CHAR(DATE_TRUNC('month', invoice_date), 'YYYYMMDD')::INT AS date_key,
        SUM(line_revenue)                           AS gross_revenue,
        SUM(net_revenue)                            AS net_revenue,
        SUM(net_revenue)                            AS mrr,
        SUM(net_revenue) * 12                       AS arr,
        AVG(net_revenue)                            AS arpu
    FROM {{ ref('fact_invoice') }}
    WHERE transaction_type = 'SALE'
      AND customer_surrogate_key IS NOT NULL
    GROUP BY 1,2,3
)

SELECT
    md5(m.customer_surrogate_key || m.revenue_month::TEXT) AS revenue_key,
    m.customer_surrogate_key,
    m.date_key,
    m.revenue_month,
    m.gross_revenue,
    m.net_revenue,
    m.mrr,
    m.arr,
    m.arpu,
    dc.contract_surrogate_key,
    COALESCE(dc.churn_probability, 0.10) AS churn_probability

FROM monthly m

LEFT JOIN {{ ref('dim_customer') }} dcu
    ON m.customer_surrogate_key = dcu.customer_surrogate_key

LEFT JOIN {{ ref('dim_contract') }} dc
    ON dcu.customer_id = dc.customer_id
    AND dc.is_current = TRUE
