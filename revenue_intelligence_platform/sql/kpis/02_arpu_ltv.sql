-- ARPU and estimated LTV by customer segment
-- LTV = avg monthly revenue × 24 months × 65% gross margin

SELECT
    dc.segment,
    COUNT(DISTINCT fr.customer_surrogate_key)   AS customer_count,
    ROUND(AVG(fr.mrr)::numeric, 2)              AS avg_mrr,
    ROUND(AVG(fr.arpu)::numeric, 2)             AS arpu_monthly,
    ROUND(AVG(fr.mrr * 24 * 0.65)::numeric, 2) AS estimated_ltv_24m
FROM gold.fact_revenue fr
JOIN gold.dim_customer dc
    ON fr.customer_surrogate_key = dc.customer_surrogate_key
GROUP BY 1
ORDER BY estimated_ltv_24m DESC;
