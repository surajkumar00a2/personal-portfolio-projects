-- ═══════════════════════════════════════════════════════
-- GOLD SCHEMA — Star Schema DDL
-- Run: psql -d revenue_intelligence -f sql/ddl/gold_schema.sql
-- ═══════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS gold.dim_date (
  date_key       INT PRIMARY KEY,
  full_date      DATE NOT NULL,
  day_of_week    VARCHAR(10),
  day_num        SMALLINT,
  week_num       SMALLINT,
  month_num      SMALLINT,
  month_name     VARCHAR(10),
  quarter_num    SMALLINT,
  fiscal_year    SMALLINT,
  fiscal_quarter VARCHAR(6),
  is_weekend     BOOLEAN
);

CREATE TABLE IF NOT EXISTS gold.dim_customer (
  customer_surrogate_key  SERIAL PRIMARY KEY,
  customer_id             VARCHAR(20),
  country                 VARCHAR(50),
  segment                 VARCHAR(30),
  churn_flag              BOOLEAN DEFAULT FALSE,
  churn_probability       NUMERIC(5,4),
  ltv_band                VARCHAR(10),
  effective_from          DATE NOT NULL,
  effective_to            DATE NOT NULL DEFAULT '9999-12-31',
  is_current              BOOLEAN DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS gold.dim_product (
  product_surrogate_key  SERIAL PRIMARY KEY,
  stock_code             VARCHAR(20),
  description            TEXT,
  list_price             NUMERIC(10,2),
  effective_from         DATE NOT NULL,
  effective_to           DATE NOT NULL DEFAULT '9999-12-31',
  is_current             BOOLEAN DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS gold.dim_contract (
  contract_surrogate_key  SERIAL PRIMARY KEY,
  customer_id             VARCHAR(20),
  contract_type           VARCHAR(30),
  payment_method          VARCHAR(40),
  tenure_months           INT,
  monthly_charges         NUMERIC(10,2),
  churn_probability       NUMERIC(5,4),
  effective_from          DATE NOT NULL,
  effective_to            DATE NOT NULL DEFAULT '9999-12-31',
  is_current              BOOLEAN DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS gold.fact_invoice (
  invoice_line_key        BIGSERIAL PRIMARY KEY,
  invoice_no              VARCHAR(20) NOT NULL,
  customer_surrogate_key  INT REFERENCES gold.dim_customer(customer_surrogate_key),
  product_surrogate_key   INT REFERENCES gold.dim_product(product_surrogate_key),
  date_key                INT REFERENCES gold.dim_date(date_key),
  transaction_type        VARCHAR(20),
  quantity                INT,
  unit_price              NUMERIC(10,2),
  discount_amount         NUMERIC(10,2) DEFAULT 0,
  line_revenue            NUMERIC(12,2),
  net_revenue             NUMERIC(12,2),
  country                 VARCHAR(50),
  is_void                 BOOLEAN DEFAULT FALSE,
  _load_timestamp         TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS gold.fact_revenue (
  revenue_key             BIGSERIAL PRIMARY KEY,
  customer_surrogate_key  INT REFERENCES gold.dim_customer(customer_surrogate_key),
  contract_surrogate_key  INT REFERENCES gold.dim_contract(contract_surrogate_key),
  date_key                INT REFERENCES gold.dim_date(date_key),
  revenue_month           DATE NOT NULL,
  gross_revenue           NUMERIC(12,2),
  net_revenue             NUMERIC(12,2),
  mrr                     NUMERIC(12,2),
  arr                     NUMERIC(12,2),
  arpu                    NUMERIC(10,2),
  churn_probability       NUMERIC(5,4)
);
