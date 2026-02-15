-- ═══════════════════════════════════════════════════════════════
-- RECONCILIATION CHECK — Bronze vs Gold
-- Acceptable delta: < 5% (excluded rows account for the gap)
-- Run after every full dbt build
-- ═══════════════════════════════════════════════════════════════

WITH bronze_total AS (
    SELECT
        'Bronze — Raw Gross Revenue'            AS layer,
        COUNT(*)                                AS row_count,
        ROUND(SUM("quantity" * "unitprice")::numeric, 2) AS total_revenue
    FROM bronze.online_retail
    WHERE "quantity" > 0
      AND "unitprice" > 0
),

gold_total AS (
    SELECT
        'Gold — Net Revenue (SALE only)'        AS layer,
        COUNT(*)                                AS row_count,
        ROUND(SUM(line_revenue)::numeric, 2)    AS total_revenue
    FROM gold.fact_invoice
    WHERE transaction_type = 'SALE'
),

comparison AS (
    SELECT * FROM bronze_total
    UNION ALL
    SELECT * FROM gold_total
)

SELECT
    layer,
    row_count,
    total_revenue,
    ROUND(
        100.0 * (
            total_revenue - LAG(total_revenue) OVER (ORDER BY layer DESC)
        ) / NULLIF(LAG(total_revenue) OVER (ORDER BY layer DESC), 0)
    , 2)                                        AS delta_pct
FROM comparison;
