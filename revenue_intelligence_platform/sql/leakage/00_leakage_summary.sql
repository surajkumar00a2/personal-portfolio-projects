-- ═══════════════════════════════════════════════════════════════
-- LEAKAGE SUMMARY — All 5 vectors in one query
-- ═══════════════════════════════════════════════════════════════

SELECT
    leakage_type,
    instances,
    ROUND(estimated_leakage::numeric, 2)        AS estimated_leakage_gbp,
    ROUND(
        100.0 * estimated_leakage
        / SUM(estimated_leakage) OVER ()
    , 1)                                        AS pct_of_total_leakage
FROM (

    SELECT
        'Price Anomaly (High + Critical)'       AS leakage_type,
        COUNT(*)                                AS instances,
        SUM(ABS(revenue_variance))              AS estimated_leakage
    FROM gold.v_price_anomalies
    WHERE severity IN ('HIGH', 'CRITICAL')

    UNION ALL

    SELECT
        'Open AR — Collections Risk',
        COUNT(*),
        SUM(invoice_total)
    FROM gold.v_open_ar
    WHERE collection_status IN (
        'ESCALATE TO COLLECTIONS', 'WRITE-OFF RISK'
    )

    UNION ALL

    SELECT
        'High Refund Rate Products',
        COUNT(*),
        SUM(refund_revenue)
    FROM gold.v_refund_analysis
    WHERE risk_flag LIKE 'CRITICAL%'
       OR risk_flag LIKE 'HIGH%'

    UNION ALL

    SELECT
        'Churn-Weighted Revenue at Risk (90d)',
        COUNT(*),
        SUM(revenue_at_risk_90d)
    FROM gold.v_revenue_at_risk

) leakage_vectors
ORDER BY estimated_leakage_gbp DESC;
