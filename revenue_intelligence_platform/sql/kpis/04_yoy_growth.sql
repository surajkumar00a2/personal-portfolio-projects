-- Year-over-year revenue growth
-- Source: gold.fact_invoice + gold.dim_date

WITH yearly AS (
    SELECT
        dd.fiscal_year,
        ROUND(SUM(fi.net_revenue)::numeric, 2)  AS annual_revenue
    FROM gold.fact_invoice fi
    JOIN gold.dim_date dd
        ON fi.date_key = dd.date_key
    WHERE fi.transaction_type = 'SALE'
    GROUP BY 1
)

SELECT
    fiscal_year,
    annual_revenue,
    LAG(annual_revenue) OVER (ORDER BY fiscal_year) AS prior_year_revenue,
    ROUND((
        annual_revenue - LAG(annual_revenue)
            OVER (ORDER BY fiscal_year)
    ) / NULLIF(
        LAG(annual_revenue) OVER (ORDER BY fiscal_year), 0
    ) * 100, 2)                                 AS yoy_growth_pct
FROM yearly
ORDER BY 1;
