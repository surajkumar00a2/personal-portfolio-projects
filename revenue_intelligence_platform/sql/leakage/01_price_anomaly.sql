-- ═══════════════════════════════════════════════════════════════
-- LEAKAGE VECTOR 1: Price Anomaly Detection
-- Method: Z-Score per SKU — flags unit prices > 1.5 SD from mean
-- Business risk: Revenue understatement or overcharging customers
-- ═══════════════════════════════════════════════════════════════

CREATE OR REPLACE VIEW gold.v_price_anomalies AS

WITH price_stats AS (
    SELECT
        stock_code,
        AVG(unit_price)                         AS mean_price,
        STDDEV(unit_price)                      AS sd_price,
        COUNT(*)                                AS sample_size
    FROM gold.fact_invoice
    WHERE transaction_type = 'SALE'
      AND unit_price > 0
    GROUP BY 1
    HAVING COUNT(*) >= 10
),

anomalies AS (
    SELECT
        fi.invoice_no,
        fi.invoice_date,
        fi.stock_code,
        fi.unit_price,
        fi.quantity,
        ps.mean_price,
        ps.sd_price,
        ROUND(
            (fi.unit_price - ps.mean_price)
            / NULLIF(ps.sd_price, 0)
        , 3)                                    AS z_score,
        ROUND(
            fi.quantity * (fi.unit_price - ps.mean_price)
        , 2)                                    AS revenue_variance,
        fi.country
    FROM gold.fact_invoice fi
    JOIN price_stats ps USING (stock_code)
    WHERE ABS(
        (fi.unit_price - ps.mean_price)
        / NULLIF(ps.sd_price, 0)
    ) > 1.5
)

SELECT
    *,
    CASE
        WHEN ABS(z_score) > 3   THEN 'CRITICAL'
        WHEN ABS(z_score) > 2   THEN 'HIGH'
        ELSE                         'MEDIUM'
    END                                         AS severity

FROM anomalies
ORDER BY ABS(z_score) DESC;
