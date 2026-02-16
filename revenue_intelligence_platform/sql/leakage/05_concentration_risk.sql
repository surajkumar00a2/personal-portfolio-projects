-- ═══════════════════════════════════════════════════════════════
-- LEAKAGE VECTOR 5: Geographic Concentration Risk
-- Method: Revenue share per country — flags over-dependence
-- Business risk: Single market exposure = revenue fragility
-- ═══════════════════════════════════════════════════════════════

CREATE OR REPLACE VIEW gold.v_concentration_risk AS

WITH country_revenue AS (
    SELECT
        country,
        ROUND(SUM(net_revenue)::numeric, 2)     AS total_revenue,
        COUNT(DISTINCT customer_surrogate_key)  AS customer_count,
        COUNT(DISTINCT invoice_no)              AS invoice_count
    FROM gold.fact_invoice
    WHERE transaction_type = 'SALE'
    GROUP BY 1
),

total AS (
    SELECT SUM(total_revenue) AS grand_total
    FROM country_revenue
)

SELECT
    cr.country,
    cr.total_revenue,
    cr.customer_count,
    cr.invoice_count,
    ROUND(
        100.0 * cr.total_revenue / t.grand_total
    , 2)                                        AS revenue_share_pct,
    SUM(
        100.0 * cr.total_revenue / t.grand_total
    ) OVER (
        ORDER BY cr.total_revenue DESC
    )                                           AS cumulative_share_pct,
    CASE
        WHEN 100.0 * cr.total_revenue
             / t.grand_total > 50               THEN 'CRITICAL CONCENTRATION'
        WHEN 100.0 * cr.total_revenue
             / t.grand_total > 20               THEN 'HIGH CONCENTRATION'
        WHEN 100.0 * cr.total_revenue
             / t.grand_total > 10               THEN 'MODERATE'
        ELSE                                         'DIVERSIFIED'
    END                                         AS concentration_flag

FROM country_revenue cr
CROSS JOIN total t
ORDER BY cr.total_revenue DESC;
