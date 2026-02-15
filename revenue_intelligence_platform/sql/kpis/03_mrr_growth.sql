-- Month-over-month MRR growth rate
-- Negative = contraction, positive = expansion

WITH monthly AS (
    SELECT
        revenue_month,
        SUM(mrr) AS total_mrr,
        SUM(arr) AS implied_arr,
        COUNT(DISTINCT customer_surrogate_key) AS active_customers
    FROM gold.fact_revenue
    GROUP BY revenue_month
)

SELECT
    TO_CHAR(revenue_month, 'YYYY-MM') AS month,
    ROUND(total_mrr::numeric, 2)      AS total_mrr,
    ROUND(implied_arr::numeric, 2)    AS implied_arr,
    active_customers,
    ROUND(
        100.0 * (
            total_mrr - LAG(total_mrr) OVER (ORDER BY revenue_month)
        )
        / NULLIF(LAG(total_mrr) OVER (ORDER BY revenue_month), 0),
        2
    ) AS mrr_growth_pct
FROM monthly
ORDER BY revenue_month;
