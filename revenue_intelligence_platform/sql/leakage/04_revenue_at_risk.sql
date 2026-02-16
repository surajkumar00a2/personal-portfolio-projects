-- ═══════════════════════════════════════════════════════════════
-- LEAKAGE VECTOR 4: Churn-Weighted Revenue at Risk
-- Method: churn_probability × MRR per customer segment
-- Business risk: Forward revenue loss from at-risk customers
-- ═══════════════════════════════════════════════════════════════

CREATE OR REPLACE VIEW gold.v_revenue_at_risk AS

WITH latest_month AS (
    SELECT MAX(revenue_month) AS max_month
    FROM gold.fact_revenue
),

customer_mrr AS (
    SELECT
        fr.customer_surrogate_key,
        fr.mrr,
        fr.arr,
        fr.churn_probability,
        dc.segment,
        dc.country,
        dc.ltv_band
    FROM gold.fact_revenue fr
    JOIN gold.dim_customer dc
        ON fr.customer_surrogate_key = dc.customer_surrogate_key
    JOIN latest_month lm
        ON fr.revenue_month = lm.max_month
    WHERE fr.churn_probability >= 0.25
)

SELECT
    customer_surrogate_key,
    segment,
    country,
    ltv_band,
    ROUND(mrr::numeric, 2)                      AS current_mrr,
    ROUND(arr::numeric, 2)                      AS arr_exposure,
    churn_probability,
    ROUND(
        (churn_probability * mrr)::numeric, 2
    )                                           AS revenue_at_risk_30d,
    ROUND(
        (churn_probability * mrr * 3)::numeric, 2
    )                                           AS revenue_at_risk_90d,
    CASE
        WHEN churn_probability >= 0.40          THEN 'CRITICAL'
        WHEN churn_probability >= 0.28          THEN 'HIGH'
        ELSE                                         'MEDIUM'
    END                                         AS risk_tier

FROM customer_mrr
ORDER BY revenue_at_risk_90d DESC;
