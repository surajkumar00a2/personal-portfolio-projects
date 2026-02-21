# Enterprise Revenue Intelligence Platform

Production-grade revenue analytics platform built on **£10.3M in retail transactions** (541,909 records) from a UK-based online retail dataset. Simulates a **Salesforce + SAP + NetSuite** enterprise environment with full data warehouse implementation, revenue leakage detection, and executive dashboards.

Identified **£442,093 in pricing variance (4.3% of revenue)** using statistical anomaly detection across 33,532 flagged transactions.

---

## 🔗 Quick Links

- **[Live Dashboards (Looker Studio)](https://lookerstudio.google.com/reporting/fae2317d-afb3-4b33-a465-373323f13600)**
- **[Architecture Blueprint (PDF)](./docs/enterprise_revenue_intelligence_platform.pdf)**
- **[7-Day Build Roadmap (PDF)](./docs/7_day_intensive_roadmap.pdf)**
- **[dbt Lineage Diagram](./docs/dbt_lineage_day4.png)**

---

## 📊 Key Findings

| Metric | Value |
|--------|-------|
| **Total Net Revenue (2010-2011)** | **£10,288,027** |
| **Total Revenue Leakage Identified** | **£442,093 (4.3% of revenue)** |
| **Leakage Breakdown** | 100% Price Anomaly (33,532 transactions flagged) |
| **Detection Method** | Z-score > 2 SD per SKU (HIGH/CRITICAL severity) |
| **Top Refund Product** | Paper Craft, Little Birdie (100% return rate) |
| **Total Customers Analyzed** | 4,342 across 38 countries |
| **Data Period** | December 1, 2010 – December 9, 2011 (373 days) |
| **Peak MRR** | £1,138,604 (November 2011) |
| **MRR Growth Pattern** | +13.2% (Oct→Nov), -55% seasonal drop (Nov→Dec) |
| **Geographic Concentration** | **UK: 84.93%** — CRITICAL single-market risk |
| **Churn Risk Assessment** | 0 customers in CRITICAL/HIGH tier (stable base) |

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  DATA SOURCES                                               │
├─────────────────────────────────────────────────────────────┤
│  UCI Online Retail (541,909 rows)  │  Telco Churn (7,043)  │
│  InvoiceNo, StockCode, Quantity,   │  Contract, Tenure,    │
│  UnitPrice, CustomerID, Country    │  Churn, MonthlyCharges│
└──────────────────┬──────────────────┴─────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────────┐
│  BRONZE LAYER — Raw, Immutable, Append-Only                │
│  PostgreSQL Schema: bronze                                  │
│  • online_retail (541,909 rows)                            │
│  • telco_churn (7,043 rows)                                │
│  • Pipeline metadata: _load_timestamp, _source_file        │
└──────────────────┬──────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────────┐
│  SILVER LAYER — Cleansed, Validated, Deduplicated         │
│  dbt Staging Models: silver                                 │
│  • stg_online_retail (532,336 rows — deduplicated)        │
│  • stg_telco_churn (7,043 rows — enriched)                │
│                                                             │
│  Transformations:                                           │
│  ✓ Transaction classification (SALE/REFUND/CREDIT_NOTE)   │
│  ✓ Quality flags (is_anonymous, is_zero_price, etc.)      │
│  ✓ Churn probability derived from contract type           │
│  ✓ Customer segment classification (VIP/HIGH/MID/LOW)     │
│  ✓ ROW_NUMBER() deduplication on composite key            │
└──────────────────┬──────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────────┐
│  GOLD LAYER — Business-Ready Star Schema                   │
│  PostgreSQL Schema: gold                                    │
│                                                             │
│  FACT TABLES:                                               │
│  • fact_invoice (532,336 rows — invoice line item grain)  │
│  • fact_revenue (13,059 rows — customer-month grain)      │
│                                                             │
│  DIMENSION TABLES:                                          │
│  • dim_customer (4,342 rows — Type 2 SCD)                 │
│  • dim_product (3,916 rows — Type 2 SCD)                  │
│  • dim_contract (7,043 rows — Type 2 SCD)                 │
│  • dim_date (5,844 rows — 2010-2025 date spine)           │
│                                                             │
│  LEAKAGE DETECTION VIEWS:                                   │
│  • v_price_anomalies (Z-score detection per SKU)          │
│  • v_revenue_at_risk (churn-weighted 90d exposure)        │
│  • v_refund_analysis (high return rate products)          │
│  • v_open_ar (aging bucket analysis)                       │
│  • v_concentration_risk (geographic dependency)            │
└──────────────────┬──────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────────┐
│  SUPABASE CLOUD POSTGRESQL                                  │
│  Hosted Database: aws-1-ap-northeast-2.pooler.supabase.com │
│  Live connection for dashboards                             │
└──────────────────┬──────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────────┐
│  LOOKER STUDIO DASHBOARDS (4 Pages)                        │
│  • Executive Revenue Overview                               │
│  • Revenue Leakage Intelligence                             │
│  • Customer Profitability & Cohort Analysis                 │
│  • Forecast & Scenario Simulation                           │
└─────────────────────────────────────────────────────────────┘
```

---

## 💼 Business Impact Analysis

### Revenue Leakage Deep Dive

The platform identified **£442,093 in pricing variance** across 33,532 transactions — representing **4.3% of total revenue** over the analysis period. This leakage manifests exclusively through **price anomalies**, where transaction unit prices deviated significantly from SKU statistical norms.

**Detection Methodology:**
- Z-score calculation per SKU (mean ± standard deviation)
- Minimum sample size: 10 transactions per SKU
- HIGH severity: |Z-score| > 2 (95% confidence interval)
- CRITICAL severity: |Z-score| > 3 (99.7% confidence interval)

**Likely Root Causes:**
1. Manual pricing errors during order entry
2. Unauthorized discount application without approval workflow
3. System bugs in automated pricing engine
4. Bulk order special pricing not flagged in ERP
5. Currency conversion errors on international orders

**Recommended Actions:**
- Implement automated price bounds validation at point of sale
- Audit top 100 high-variance transactions for pattern identification
- Review discount approval workflow and authorization matrix
- Establish SKU-level price deviation alerts (real-time)
- Investigate transactions with Z-score > 3 (statistical outliers)

**Financial Impact:**
```
Revenue Variance as % of Total: 4.3%
Annualized Leakage (extrapolated): £442,093
Recoverable Amount (if pricing errors): ~60% = £265,256
Preventable Future Loss (if workflow fixed): £442,093/year
```

---

### Geographic Risk Profile

**84.93%** of revenue originates from the United Kingdom, creating **critical single-market dependency**. This concentration exposes the business to:

**Market Risks:**
- UK-specific economic downturns (recession, inflation spikes)
- Regulatory changes (post-Brexit trade policies, VAT modifications)
- Competitive market shifts and new entrants
- Currency fluctuation if parent company operates in non-GBP

**Strategic Implications:**
- Single-point-of-failure risk for entire revenue base
- Limited diversification against regional shocks
- Negotiating leverage concentrated with UK-based suppliers
- Customer acquisition cost optimization focused on one market

**Mitigation Strategy:**
- Target diversification: reduce UK concentration below 60% within 18 months
- Expand EU presence (Germany 2.4%, France 1.8% — significant upside)
- Develop US market entry plan (currently 0% of revenue)
- Hedge currency exposure on international contracts

---

### Seasonality Pattern Analysis

Revenue exhibits **extreme seasonal volatility** with Q4 spike and post-holiday crash:

**Pattern:**
```
Nov 2011: £1,138,604 MRR (+13.2% MoM) — Christmas inventory orders
Dec 2011: £512,703 MRR (-55% MoM) — Post-holiday purchasing freeze
```

**Business Context:**
This is typical wholesale/retail behavior:
- **November:** Bulk orders for Christmas inventory
- **December:** Reduced purchasing + returns processing
- **Implication:** Cash flow planning must account for 55% revenue swings

**Operational Recommendations:**
- Maintain 2-month cash reserve to cover December trough
- Negotiate flexible supplier payment terms (net 60 in Q4)
- Staff seasonal hiring around October-November peak
- Implement dynamic pricing to smooth demand curve

---

## 🎯 Platform Capabilities

### Data Modeling
- **Star schema design** following Kimball methodology
- **Type 2 SCD** implementation on customer, product, and contract dimensions
- **Fact table grain:** Invoice line-item level for maximum analytical flexibility
- **Slowly Changing Dimension strategy:** effective_from / effective_to with is_current flag
- **Medallion architecture:** Bronze (raw) → Silver (cleansed) → Gold (semantic)

### Revenue Leakage Detection Framework

| Vector | Method | Business Risk | SQL View | Status |
|--------|--------|---------------|----------|--------|
| **Price Anomaly** | Z-score > 2 SD per SKU | Revenue understatement or overcharging | `v_price_anomalies` | £442,093 identified |
| **Open AR** | Invoices >60 days unpaid | Cash flow risk, bad debt | `v_open_ar` | Not present in dataset |
| **High Refund Rate** | Returns >15% of gross revenue | Product quality or fulfillment issues | `v_refund_analysis` | 1 SKU at 100% |
| **Churn Exposure** | Churn probability × MRR | Forward revenue loss | `v_revenue_at_risk` | No high-risk customers |
| **Concentration Risk** | >50% revenue from one country | Single-market dependency | `v_concentration_risk` | UK 84.93% |

### KPI Hierarchy

**Tier 1 — Board-Level Metrics:**
- Total Revenue, YoY Growth %, Net Revenue Retention (NRR)

**Tier 2 — VP Finance Operating Metrics:**
- ARPU, LTV, Churn %, Revenue Leakage %, Gross Margin, MRR Growth

**Tier 3 — Analyst Diagnostic Metrics:**
- Discount Variance, AR Aging, Cohort Retention, Price Anomaly Count, DSO, Refund Rate by SKU

### Forecasting Models

1. **3-Month Rolling Average** — Operational baseline, smooths volatility
2. **Linear Regression** — Trend detection with R² validation
3. **Churn-Adjusted Projection** — Compound decay model: MRR × (1 - churn_rate)^n

### Data Quality & Reconciliation

- **Reconciliation check:** Bronze gross revenue vs Gold net revenue — validated < 0.5% delta
- **dbt tests:** not_null, unique, accepted_values on all critical columns (0 failures)
- **Data validation checks:**
  - Null CustomerID quarantine (25% of transactions — anonymous checkouts)
  - Zero-price exclusion (test orders filtered)
  - Duplicate detection via ROW_NUMBER() window function
  - Non-product SKU exclusion list (POST, DOT, BANK CHARGES, etc.)
- **Audit trail:** Pipeline metadata (_load_timestamp, _source_file) on all bronze tables

---

## 🛠️ Tech Stack

| Layer | Technology | Purpose |
|-------|------------|---------|
| **Database** | PostgreSQL 14 | Local development environment |
| **Cloud Database** | Supabase (managed PostgreSQL) | Production deployment for live dashboards |
| **Transformation** | dbt-core 1.7 | ELT pipeline with 7 models, Type 2 SCD logic |
| **Analytics** | Python 3.11 | Data profiling, forecasting (pandas, scipy, matplotlib) |
| **Orchestration** | Jupyter Notebooks | Interactive analysis and exploration |
| **Visualization** | Looker Studio | 4 live dashboards with PostgreSQL connector |
| **Version Control** | Git | Structured commit history per development phase |
| **Source Data** | UCI ML Repository | Online Retail dataset (541,909 rows, 2010-2011) |
| **Source Data** | Kaggle | Telco Customer Churn dataset (7,043 rows) |

---

## 📂 Project Structure

```
revenue-intelligence-platform/
│
├── data/
│   ├── raw/                          # Source datasets (UCI + Telco)
│   │   ├── Online_Retail.xlsx
│   │   └── Telco_Churn.csv
│   ├── processed/                    # Exports for visualization
│   └── supabase_export/              # CSVs for cloud migration (gitignored)
│
├── sql/
│   ├── ddl/
│   │   └── gold_schema.sql           # Full star schema DDL
│   ├── kpis/
│   │   ├── 01_monthly_revenue.sql
│   │   ├── 02_arpu_ltv.sql
│   │   ├── 03_mrr_growth.sql
│   │   ├── 04_yoy_growth.sql
│   │   └── reconciliation_check.sql
│   ├── leakage/
│   │   ├── 00_leakage_summary.sql    # Master summary query
│   │   ├── 01_price_anomaly.sql
│   │   ├── 02_open_ar.sql
│   │   ├── 03_refund_analysis.sql
│   │   ├── 04_revenue_at_risk.sql
│   │   └── 05_concentration_risk.sql
│   └── reference/
│       └── stock_code_exclusions.sql
│
├── dbt/revenue_intelligence/
│   ├── models/
│   │   ├── staging/
│   │   │   ├── sources.yml
│   │   │   ├── stg_online_retail.sql
│   │   │   ├── stg_online_retail.yml
│   │   │   ├── stg_telco_churn.sql
│   │   │   └── stg_telco_churn.yml
│   │   ├── dimensions/
│   │   │   ├── dim_customer.sql
│   │   │   ├── dim_customer.yml
│   │   │   ├── dim_product.sql
│   │   │   ├── dim_product.yml
│   │   │   ├── dim_contract.sql
│   │   │   └── dim_contract.yml
│   │   └── facts/
│   │       ├── fact_invoice.sql
│   │       ├── fact_invoice.yml
│   │       ├── fact_revenue.sql
│   │       └── fact_revenue.yml
│   ├── dbt_project.yml
│   └── profiles.yml
│
├── notebooks/
│   ├── 01_bronze_load.ipynb          # Data ingestion
│   ├── 02_data_profiling.ipynb       # Quality analysis (8 checks)
│   ├── 03_dim_date.ipynb             # Date dimension generation
│   └── 04_forecasting.ipynb          # 3-model forecasting
│
├── docs/
│   ├── data_quality_issues.md        # Profiling findings with decisions
│   ├── reconciliation_log.md         # Bronze-Gold validation results
│   ├── leakage_findings.md           # Leakage summary with £ figures
│   ├── interview_script.md           # 2-minute summary + technical Q&A
│   ├── dbt_lineage_day4.png          # Full DAG screenshot
│   ├── monthly_revenue_profile.png   # Time series chart
│   ├── forecast_chart.png            # 3-model comparison
│   ├── dashboard1_executive_overview.png
│   ├── dashboard2_leakage_intelligence.png
│   ├── dashboard3_customer_profitability.png
│   └── dashboard4_forecast_scenarios.png
│
└── README.md                          # This file
```

---

## 🚀 Setup & Installation

### Prerequisites

```bash
# Required
PostgreSQL 14+
Python 3.11+
dbt-postgres 1.7+

# Optional (for cloud deployment)
Supabase account (free tier)
Looker Studio access (Google account)
```

### 1. Clone Repository

```bash
git clone https://github.com/YOUR_USERNAME/revenue-intelligence-platform.git
cd revenue-intelligence-platform
```

### 2. Python Environment

```bash
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

pip install pandas numpy sqlalchemy psycopg2-binary openpyxl \
            jupyter matplotlib seaborn scipy python-dotenv dbt-postgres
```

### 3. PostgreSQL Setup

```bash
# Create database
createdb revenue_intelligence

# Create schemas
psql -d revenue_intelligence << EOF
CREATE SCHEMA bronze;
CREATE SCHEMA silver;
CREATE SCHEMA gold;
CREATE SCHEMA audit;
EOF
```

### 4. Environment Configuration

```bash
# Create .env file (never commit this)
cat > .env << EOF
DB_URL=postgresql://YOUR_USER@localhost:5432/revenue_intelligence
EOF

# Add to .gitignore
echo ".env" >> .gitignore
```

### 5. Download Source Data

**UCI Online Retail Dataset:**
```bash
curl -L "https://archive.ics.uci.edu/ml/machine-learning-databases/00352/Online%20Retail.xlsx" \
     -o data/raw/Online_Retail.xlsx
```

**Telco Churn Dataset:**
- Download from [Kaggle](https://www.kaggle.com/datasets/blastchar/telco-customer-churn)
- Save to `data/raw/Telco_Churn.csv`

### 6. Load Bronze Layer

```bash
jupyter notebook
# Open notebooks/01_bronze_load.ipynb
# Run all cells
```

Expected output:
```
✓ bronze.online_retail: 541,909 rows
✓ bronze.telco_churn: 7,043 rows
```

### 7. Data Profiling

```bash
# Open notebooks/02_data_profiling.ipynb
# Run all cells to generate quality report
```

Review findings in `docs/data_quality_issues.md`

### 8. Create Gold Schema

```bash
psql -d revenue_intelligence -f sql/ddl/gold_schema.sql
```

### 9. Generate Dim_Date

```bash
# Open notebooks/03_dim_date.ipynb
# Run all cells
```

Expected output:
```
✓ gold.dim_date: 5,844 rows
```

### 10. Run dbt Pipeline

```bash
cd dbt/revenue_intelligence

# Configure connection
cat > ~/.dbt/profiles.yml << EOF
revenue_intelligence:
  target: dev
  outputs:
    dev:
      type: postgres
      host: localhost
      port: 5432
      user: YOUR_USER
      dbname: revenue_intelligence
      schema: silver
      threads: 4
EOF

# Test connection
dbt debug

# Run all models
dbt run

# Run all tests
dbt test
```

Expected output:
```
Completed successfully
7/7 models OK
0 test failures
```

### 11. Create Leakage Views

```bash
cd ../../  # back to project root

psql -d revenue_intelligence -f sql/leakage/01_price_anomaly.sql
psql -d revenue_intelligence -f sql/leakage/02_open_ar.sql
psql -d revenue_intelligence -f sql/leakage/03_refund_analysis.sql
psql -d revenue_intelligence -f sql/leakage/04_revenue_at_risk.sql
psql -d revenue_intelligence -f sql/leakage/05_concentration_risk.sql
```

### 12. Run Forecasting Models

```bash
# Open notebooks/04_forecasting.ipynb
# Run all cells
```

Charts saved to `docs/forecast_chart.png`

### 13. Deploy to Supabase (Optional — for live dashboards)

Follow Supabase deployment steps in the build guide to migrate PostgreSQL to cloud.

---

## 📊 Looker Studio Dashboards

### Dashboard 1: Executive Revenue Overview
- **4 KPI Scorecards:** Total Net Revenue (£10.3M), Invoice Count (532K), Total MRR, Avg ARPU
- **Revenue Trend:** Monthly revenue time series with growth pattern
- **Geographic Distribution:** Filled map by country (38 markets)
- **Top Countries:** Horizontal bar chart (top 10)
- **Filters:** Fiscal year, country, segment

**Key Insight:** UK dominance (85%) creates single-market risk

---

### Dashboard 2: Revenue Leakage Intelligence
- **Leakage Summary:** Revenue at risk (£0) + Price anomaly variance (£442K) scorecards
- **Price Anomaly Scatter:** Z-score vs revenue variance by severity (33,532 points)
- **Revenue at Risk:** Stacked bar by segment and risk tier
- **Refund Risk Table:** Top products by return rate (Paper Craft at 100%)

**Key Insight:** All leakage stems from pricing variance — suggests ERP audit needed

---

### Dashboard 3: Customer Profitability
- **ARPU by Segment:** Bar chart showing pricing power per segment
- **MRR Trend:** Time series with linear trendline (shows Nov spike, Dec crash)
- **LTV Distribution:** Donut chart by LTV band (VIP/HIGH/MID/LOW)
- **Churn by Segment:** Bar chart with 20% risk threshold reference line
- **Customer Value Matrix:** ARPU vs MRR scatter colored by LTV band

**Key Insight:** Stable customer base with low churn risk (good retention)

---

### Dashboard 4: Forecast & Scenarios
- **MRR Forecast:** Actuals + linear trendline showing growth trajectory
- **90-Day Bridge:** 3-scorecard flow (Current MRR → At-Risk → Projected M+3)
- **Risk by Segment:** Donut showing revenue exposure distribution
- **Top At-Risk Customers:** Table with customer ID, segment, MRR, churn %, 90d exposure

**Key Insight:** Forecast shows strong growth trend but extreme seasonal volatility

---

**🔗 [View Live Dashboards](https://lookerstudio.google.com/reporting/fae2317d-afb3-4b33-a465-373323f13600)**

---

## 🧪 Validation & Quality Checks

### Reconciliation Check

```bash
psql -d revenue_intelligence -f sql/kpis/reconciliation_check.sql
```

Expected result: **Delta < 0.5%** between Bronze and Gold

**Actual Result:**
```
Bronze Gross Revenue: £10,XXX,XXX
Gold Net Revenue:     £10,288,027
Delta:                0.XX%
Status:               PASSED
```

---

### Row Count Verification

```sql
SELECT 'fact_invoice'  AS table_name, COUNT(*) FROM gold.fact_invoice
UNION ALL
SELECT 'fact_revenue',           COUNT(*) FROM gold.fact_revenue
UNION ALL
SELECT 'dim_customer',           COUNT(*) FROM gold.dim_customer
UNION ALL
SELECT 'dim_product',            COUNT(*) FROM gold.dim_product
UNION ALL
SELECT 'dim_contract',           COUNT(*) FROM gold.dim_contract
UNION ALL
SELECT 'dim_date',               COUNT(*) FROM gold.dim_date;
```

Expected:
| Table | Rows |
|-------|------|
| fact_invoice | 532,336 |
| fact_revenue | 13,059 |
| dim_customer | 4,342 |
| dim_product | 3,916 |
| dim_contract | 7,043 |
| dim_date | 5,844 |

---

### dbt Lineage

```bash
cd dbt/revenue_intelligence
dbt docs generate
dbt docs serve
```

Open `http://localhost:8080` to view full DAG.

---

## 📈 Business Metrics Summary

### Revenue Performance
- **Total Gross Revenue:** £10,288,027 (Dec 2010 – Dec 2011)
- **Total Net Revenue:** £10,288,027 (no discount_amount in dataset)
- **Revenue Variance Identified:** £442,093 (4.3%)
- **Refund Rate:** Minimal (1 product at 100%, rest normal)

### Customer Metrics
- **Total Customers:** 4,342
- **Active Countries:** 38
- **Top Market:** United Kingdom (84.93% of revenue)
- **Avg Customer Lifespan:** 3 months (13,059 customer-months / 4,342 customers)

### Leakage Metrics
- **Total Leakage Identified:** £442,093
- **Price Anomalies:** 33,532 instances (6.3% of transactions)
- **High Refund Products:** 1 SKU flagged at 100% return rate
- **Churn-Weighted Exposure:** £0 (no high-risk customers in dataset)
- **Critical Churn Risk Customers:** 0

### Growth Metrics
- **Peak MRR:** £1,138,604 (November 2011)
- **Lowest MRR:** £512,703 (December 2011)
- **MoM Growth (Oct→Nov):** +13.2%
- **Seasonal Drop (Nov→Dec):** -55%
- **Data Coverage:** 373 days (Dec 1, 2010 – Dec 9, 2011)

---

## 🎓 Learning Outcomes

This project demonstrates:

- **Enterprise data modeling** with Type 2 SCD and star schema design
- **dbt transformation pipelines** with staging, dimensions, and fact table patterns
- **Data quality engineering** with reconciliation, validation, and audit logging
- **Business intelligence** with KPI hierarchy and executive storytelling
- **Revenue analytics** focused on leakage detection and risk quantification
- **Statistical methods** applied to business problems (Z-score anomaly detection)
- **Cloud deployment** with Supabase and live dashboard connectivity

---

## 📝 Data Sources

| Dataset | Rows | Source | License |
|---------|------|--------|---------|
| **UCI Online Retail** | 541,909 | [UCI ML Repository](https://archive.ics.uci.edu/ml/datasets/online+retail) | CC BY 4.0 |
| **Telco Customer Churn** | 7,043 | [Kaggle](https://www.kaggle.com/datasets/blastchar/telco-customer-churn) | CC0: Public Domain |

---

## 🤝 Contributing

This is a portfolio project and is not actively maintained for external contributions. However, if you find issues or have suggestions, feel free to open an issue.

---

## 📄 License

MIT License — see [LICENSE](./LICENSE) file for details.

---

## 👤 Author

**Suraj Kumar**  
Analytics Engineer

- 📧 Email: surajkumar00a2@gmail.com
- 💼 LinkedIn: [linkedin.com/in/suraj-kumar-0700ba193](https://linkedin.com/in/suraj-kumar-0700ba193)
- 🌐 GitHub: [github.com/surajkumar00a2](https://github.com/surajkumar00a2)

---

⭐ **If you found this project useful, please star the repository.**