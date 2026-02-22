# 📂 Data Engineering Portfolio – Suraj Kumar

Production-grade data engineering projects demonstrating **end-to-end pipelines, cloud architecture, data modeling, and analytics engineering**.

Each project is self-contained with full documentation and reproducible setup.

---

## 📊 Featured Projects

### 1. 💰 Enterprise Revenue Intelligence Platform
**Tech:** PostgreSQL, dbt, Python, Looker Studio, Supabase  
📁 **[View Project →](./revenue_intelligence_platform)** | 🔗 **[Live Dashboards →](https://lookerstudio.google.com/reporting/fae2317d-afb3-4b33-a465-373323f13600)**

Production **revenue analytics platform** on £10.3M of retail transactions. Identified **£442K in pricing variance (4.3% of revenue)** using statistical anomaly detection across 541,909 transactions.

**Key Capabilities**
- **Revenue leakage detection:** Z-score price anomaly detection across 33,532 flagged transactions
- **Star schema warehouse:** 3 fact tables + 5 dimensions with Type 2 SCD (dbt + PostgreSQL)
- **Geographic risk analysis:** Flagged 85% UK revenue concentration as critical single-market dependency
- **MRR forecasting:** 3-method ensemble with seasonality pattern recognition
- **Live dashboards:** 4 executive dashboards on Supabase cloud via Looker Studio

**Why it stands out:** Quantifies business risk in £ using statistical methods. Goes beyond descriptive reporting to CFO-level decision intelligence — 4.3% revenue variance identified and surfaced for action.

---

### 2. 🌦️ Weather Data Platform with Quality Monitoring
**Tech:** Python, AWS Lambda, S3, Glue, Athena, CloudWatch  
📁 **[View Project →](./weather_data_platform)**

**Serverless data lake** on AWS with continuous **data quality monitoring** at ingestion time. Detects schema drift and anomalies before dashboards break.

**Key Capabilities**
- Bronze → Silver → Gold ETL architecture
- Real-time quality metrics: completeness, consistency, timeliness
- CloudWatch dashboards & alerting
- Event-driven, cost-optimized (~$1.60/month)

**Why it stands out:** Goes beyond ingestion — focuses on **data trust & observability** in production.

---

### 3. 📈 Automated Stock & News Data Pipeline
**Tech:** Python, Apache Airflow, PostgreSQL, Docker  
📁 **[View Project →](./stock_news_pipeline)**

Orchestrated ETL pipeline extracting daily stock prices and financial news with validation, retries, and scheduling.

**Key Capabilities**
- Daily OHLC stock ingestion + financial news scraping
- Airflow DAGs with data quality checks
- Dockerized setup with PostgreSQL persistence

---

### 4. 🛒 Multi-Source E-Commerce Price Tracker
**Tech:** Python, Selenium, PostgreSQL, Streamlit  
📁 **[View Project →](./ecommerce_price_tracker)**

System for tracking product prices across e-commerce platforms with historical trend analysis.

**Key Capabilities**
- Multi-site web scraping with Selenium
- Scheduled price tracking
- Interactive Streamlit dashboard

---

## 🛠️ Core Skill Set

### Data Engineering & Modeling
- ETL/ELT pipeline design (batch & streaming)
- Star schema & dimensional modeling (Kimball methodology)
- Data quality & observability frameworks
- Type 2 SCD implementation
- dbt transformations & testing

### Languages & Frameworks
- **Python** (pandas, NumPy, scipy, Airflow)
- **SQL** (PostgreSQL, MySQL — complex queries, window functions, CTEs)

### Cloud & Infrastructure
- **AWS** (Lambda, S3, Glue, Athena, CloudWatch, IAM)
- **Supabase** (managed PostgreSQL)
- Docker, Git

### Analytics & Visualization
- **Looker Studio** (live dashboards, custom SQL, blended data)
- Streamlit
- Data profiling & statistical analysis

### Orchestration & Automation
- Apache Airflow (DAG design, retries, alerting)
- Event-driven architectures
- Scheduled pipelines

### Data Governance
- Reconciliation logic & validation
- Schema drift detection
- Cost optimization
- IAM security & access control

---

## 👤 About Me

**Suraj Kumar**  
Analytics Engineer with **3+ years** building production ETL pipelines, cloud automation, and enterprise analytics platforms.

Specialized in **data quality engineering, dimensional modeling, and business intelligence** — turning raw data into executive-ready insights.

- 📧 Email: surajkumar00a2@gmail.com  
- 💼 LinkedIn: [linkedin.com/in/suraj-kumar-0700ba193](https://linkedin.com/in/suraj-kumar-0700ba193)  
- 🌐 GitHub: [github.com/surajkumar00a2](https://github.com/surajkumar00a2)  

---

⭐ **If these projects are useful, please star the repository.**
