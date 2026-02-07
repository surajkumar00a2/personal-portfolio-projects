# 📊 Weather Data Platform with Quality Monitoring

> Production-grade serverless data lake on AWS with automated data quality monitoring and schema drift detection

[![AWS](https://img.shields.io/badge/AWS-Serverless-FF9900?logo=amazon-aws)](https://aws.amazon.com)
[![Python](https://img.shields.io/badge/Python-3.11-3776AB?logo=python&logoColor=white)](https://www.python.org/)
[![PySpark](https://img.shields.io/badge/PySpark-3.4-E25A1C?logo=apache-spark&logoColor=white)](https://spark.apache.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Cost](https://img.shields.io/badge/Monthly_Cost-$1.61-success)](docs/ARCHITECTURE.md#cost-optimization-strategies)

---

## 🎯 What Makes This Different

This isn't just another "data lake" project. **This solves a real production problem:**

**Companies depend on external APIs** (weather, pricing, vendors, partners). But APIs fail silently:
- ❌ Schema changes without notice
- ❌ Data arrives incomplete
- ❌ Volumes drop unexpectedly
- ❌ Teams discover issues only after dashboards break

**This platform detects these problems before they cause outages.**

---

## 🏗️ Architecture
```
EventBridge → Lambda (Validation + Quality Checks) → S3 Bronze (JSON)
                   ↓                                      ↓
            CloudWatch Metrics                    S3 Metrics (Parquet)
                                                          ↓
                                    Glue Workflow (Automated)
                                        ↓            ↓
                                   Silver (Clean) → Gold (Aggregated)
                                                     ↓
                                            Athena (SQL Analytics)
```

**Full architecture details:** [docs/ARCHITECTURE.md](docs/architecture.md)

---

## 💡 Key Features

### 🔍 Data Quality Monitoring
- **4-Dimensional Quality Score** (0-100): Completeness, Consistency, Timeliness, Availability
- **Real-time detection** of missing fields, type mismatches, value range violations
- **CloudWatch dashboard** for visual monitoring

### 🔄 Schema Drift Detection
- **Automated fingerprinting** using MD5 hash of field structure
- **Change tracking**: Identifies new fields, removed fields, type changes
- **Historical comparison** against baseline schema

### ⚡ Production-Grade Pipeline
- **Medallion Architecture**: Bronze (raw) → Silver (clean) → Gold (curated)
- **Automated orchestration**: Glue workflows trigger jobs in sequence
- **Idempotent processing**: Handles retries and duplicates gracefully
- **Cost-optimized**: $1.61/month operational cost

### 📊 Analytics-Ready
- **Parquet format**: 68% storage reduction vs JSON
- **Partition pruning**: 90% query cost savings
- **5 pre-built views**: Common query patterns ready to use
- **15+ sample queries**: Quality analysis, weather analytics, drift detection

---

## 📁 Project Structure
```
weather-data-platform/
├── lambda/ingestion/          # Data ingestion with quality checks
│   ├── lambda_ingestion_v2.py # Main handler
│   ├── quality_validator.py   # Validation engine
│   └── schema_definition.py   # Expected schema
│
├── glue/                      # ETL transformations
│   ├── bronze_to_silver.py    # Clean & deduplicate
│   ├── silver_to_gold.py      # Aggregate & curate
│   └── create_workflow.sh     # Orchestration setup
│
├── athena/                    # SQL queries & DDLs
│   ├── ddl/                   # Table definitions
│   ├── queries/               # Analytics queries
│   └── views/                 # Reusable views
│
├── scripts/                   # Deployment automation
│   ├── deploy_all.sh          # One-click deployment
│   └── setup_s3_buckets.sh    # S3 initialization
│
├── iam/                       # IAM roles & policies
│   └── setup-iam-roles.sh     # Role creation
│
├── docs/                      # Documentation
│   ├── ARCHITECTURE.md        # System design
│   ├── SETUP_GUIDE.md         # Step-by-step setup
│   └── INTERVIEW_PREP.md      # Q&A, resume bullets
│
└── config/                    # Configuration
    ├── bucket-name.txt        # S3 bucket (gitignored)
    └── api-key.txt            # API key (gitignored)
```

---

## 🚀 Quick Start

### Prerequisites
- AWS Account (Free Tier)
- AWS CLI configured
- Python 3.11+
- OpenWeatherMap API key ([get free key](https://openweathermap.org/api))

### 1. Clone & Configure
```bash
git clone https://github.com/yourusername/weather-data-platform
cd weather-data-platform

# Add your API key
echo "your_openweathermap_api_key" > config/api-key.txt
```

### 2. Set Up Infrastructure
```bash
# Create IAM roles
cd iam
./setup-iam-roles.sh

# Create S3 bucket
cd ../scripts
./setup_s3_buckets.sh
```

### 3. Deploy Everything
```bash
# One-click deployment
./deploy_all.sh
```

This deploys:
- ✅ Lambda function
- ✅ Glue jobs (Bronze→Silver→Gold)
- ✅ Glue workflow (automated orchestration)
- ✅ S3 lifecycle policies
- ✅ Glue crawler schedule

### 4. Create Athena Tables

Run these DDLs in [Athena Console](https://console.aws.amazon.com/athena/):
- `athena/ddl/silver_tables.sql`
- `athena/ddl/gold_tables.sql`
- `athena/ddl/metrics_tables.sql`
- `athena/views/common_views.sql`

### 5. Verify Deployment
```bash
# Trigger initial data load
aws lambda invoke \
  --function-name weather-ingestion \
  --payload '{}' \
  response.json

# Check results
cat response.json | jq .
```

**Detailed setup:** [docs/SETUP_GUIDE.md](docs/SETUP_GUIDE.md)

---

## 📊 Data Quality Metrics

The platform tracks 4 quality dimensions:

| Metric | Definition | Alert Threshold |
|--------|------------|-----------------|
| **Completeness** | % of mandatory fields populated | < 80% |
| **Consistency** | Schema matches expected structure | Schema changed |
| **Timeliness** | Data ingested on schedule | > 10min late |
| **Availability** | API responds successfully | < 95% |

**Overall Quality Score** = Weighted average (0-100)

### Sample Queries
```sql
-- Check recent quality
SELECT * FROM v_recent_quality_issues 
WHERE date >= CURRENT_DATE - INTERVAL '7' DAY;

-- Detect schema drift
SELECT * FROM v_schema_drift_history
ORDER BY event_date DESC;

-- Latest weather by city
SELECT * FROM v_latest_weather;
```

---

## 💰 Cost Analysis

### Monthly Cost: **$1.61**

| Service | Cost |
|---------|------|
| Lambda | $0.00 (free tier) |
| S3 Storage | $0.07 |
| Glue Jobs | $1.17 |
| Glue Crawler | $0.44 |
| Athena | $0.00 (<1TB scanned) |
| CloudWatch | $0.00 (free tier) |

**Scaling:** 100 cities, hourly ingestion → **~$40/month** (still serverless)

**vs EC2-based solution:** 99% cost reduction ($1.61 vs $180/month)

---

## 🔧 Technology Stack

| Layer | Technology |
|-------|------------|
| **Ingestion** | AWS Lambda (Python 3.11), EventBridge |
| **Storage** | Amazon S3 (Bronze/Silver/Gold) |
| **Processing** | AWS Glue (PySpark 3.4) |
| **Orchestration** | Glue Workflows |
| **Catalog** | Glue Data Catalog |
| **Analytics** | Amazon Athena (Presto SQL) |
| **Monitoring** | CloudWatch Logs, Metrics, Dashboards |
| **Format** | JSON (Bronze), Parquet (Silver/Gold/Metrics) |

---

## 📚 Documentation

- **[Architecture Details](docs/ARCHITECTURE.md)** - System design, data flow, technology decisions
- **[Setup Guide](docs/SETUP_GUIDE.md)** - Step-by-step deployment instructions
- **[Interview Prep](docs/INTERVIEW_PREP.md)** - Resume bullets, Q&A, 2-minute pitch

---

## 🎓 Skills Demonstrated

✅ **Serverless Architecture** (Lambda, Glue, Athena)  
✅ **Data Quality Engineering** (validation, monitoring, alerting)  
✅ **Schema Evolution** (drift detection, version tracking)  
✅ **ETL Pipelines** (Bronze→Silver→Gold)  
✅ **Cost Optimization** (Parquet, partitioning, lifecycle policies)  
✅ **Production Monitoring** (CloudWatch metrics, dashboards)  
✅ **SQL Analytics** (Athena queries, views, optimization)  
✅ **Infrastructure Automation** (deployment scripts, workflows)

---

## 🔍 Example Use Cases

### Use Case 1: Detect Missing API Fields
```
Scenario: API stops returning humidity data
Detection: Completeness score drops to 92%
Alert: CloudWatch metric triggers notification
Action: Engineering team investigates API provider
```

### Use Case 2: Schema Change Detection
```
Scenario: API adds new field "air_quality_index"
Detection: Schema fingerprint changes (a3f5c8d9 → b7e2d1a4)
Alert: Schema drift alert with exact changes
Action: Update downstream transformations
```

### Use Case 3: Volume Anomaly
```
Scenario: API returns data for 2/3 cities (one city fails)
Detection: Volume drops by 33%
Alert: Quality score drops below threshold
Action: Retry failed city, investigate API
```

---

## 📝 License

MIT License - see [LICENSE](LICENSE) file

---

## 👤 Author

**Suraj Kumar**
[LinkedIn](www.linkedin.com/in/suraj-kumar-0700ba193) | [GitHub](https://github.com/surajkumar00a2 )

---

## 🙏 Acknowledgments

- OpenWeatherMap for free API access
- AWS Free Tier for cost-effective infrastructure
- Data engineering community for best practices

---

## ⭐ Star this repo if you found it helpful!


