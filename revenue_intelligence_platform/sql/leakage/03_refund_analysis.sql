-- ═══════════════════════════════════════════════════════════════
-- LEAKAGE VECTOR 3: High Refund Rate Products
-- Method: Refund revenue as % of gross revenue per SKU
-- Business risk: Chronic returners indicate quality or
--               fulfilment issues eroding net revenue
-- ═══════════════════════════════════════════════════════════════

CREATE OR REPLACE VIEW gold.v_refund_analysis AS

WITH by_product AS (
    SELECT
        fi.stock_code,
        dp.description,
        SUM(CASE WHEN fi.transaction_type = 'SALE'
            THEN fi.line_revenue ELSE 0 END)    AS gross_revenue,
        SUM(CASE WHEN fi.transaction_type = 'REFUND'
            THEN ABS(fi.line_revenue) ELSE 0 END) AS refund_revenue,
        COUNT(CASE WHEN fi.transaction_type = 'SALE'
            THEN 1 END)                         AS sale_count,
        COUNT(CASE WHEN fi.transaction_type = 'REFUND'
            THEN 1 END)                         AS refund_count
    FROM gold.fact_invoice fi
    LEFT JOIN gold.dim_product dp
        ON fi.product_surrogate_key = dp.product_surrogate_key
    GROUP BY 1, 2
    HAVING SUM(CASE WHEN fi.transaction_type = 'SALE'
        THEN fi.line_revenue ELSE 0 END) > 100
)

SELECT
    stock_code,
    description,
    ROUND(gross_revenue::numeric, 2)            AS gross_revenue,
    ROUND(refund_revenue::numeric, 2)           AS refund_revenue,
    sale_count,
    refund_count,
    ROUND(
        100.0 * refund_revenue
        / NULLIF(gross_revenue, 0)
    , 2)                                        AS refund_rate_pct,
    CASE
        WHEN refund_revenue / NULLIF(gross_revenue,0) > 0.30
            THEN 'CRITICAL — >30% Refund Rate'
        WHEN refund_revenue / NULLIF(gross_revenue,0) > 0.15
            THEN 'HIGH — >15% Refund Rate'
        WHEN refund_revenue / NULLIF(gross_revenue,0) > 0.05
            THEN 'MONITOR — >5% Refund Rate'
        ELSE 'NORMAL'
    END                                         AS risk_flag

FROM by_product
ORDER BY refund_rate_pct DESC;
