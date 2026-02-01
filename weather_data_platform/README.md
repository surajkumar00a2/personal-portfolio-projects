# 📊 Weather Data Platform with Quality Monitoring

> Production-grade serverless data lake on AWS with real-time data quality monitoring

[![AWS](https://img.shields.io/badge/AWS-Serverless-orange)](https://aws.amazon.com)
[![Python](https://img.shields.io/badge/Python-3.11-blue)](https://www.python.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## 🎯 Project Overview

A **hybrid data engineering project** that combines:
- ✅ Standard ETL pipeline (Bronze → Silver → Gold)
- ✅ Real-time data quality monitoring
- ✅ Schema drift detection
- ✅ Anomaly detection
- ✅ Cost-optimized serverless architecture

**What makes this unique**: Unlike typical "build a data lake" projects, this demonstrates **data observability engineering** - detecting when external APIs become unreliable before they break dashboards.

## 🏗️ Architecture
```
EventBridge → Lambda (Ingestion + Validation) → S3 Bronze (Raw)
                   ↓                                ↓
            CloudWatch Metrics              S3 Metrics (Quality)
                                                    ↓
                               Glue (Bronze → Silver → Gold)
                                                    ↓
                               Athena (SQL Analytics)
```

## 💰 Cost

**Monthly cost**: ~$1.61 (4 ingestions/day, 3 cities)

| Service | Cost |
|---------|------|
| Lambda | $0.00 (free tier) |
| S3 | $0.00 (free tier) |
| Glue | $1.17 |
| Athena | $0.00 (<1TB scanned) |
| CloudWatch | $0.00 (free tier) |

## 🚀 Quick Start

### Prerequisites
- AWS Account (Free Tier)
- AWS CLI configured
- Python 3.11+
- OpenWeatherMap API key (free)

### Setup

1. **Clone repository**
```bash
git clone <your-repo-url>
cd weather-data-platform
```

2. **Configure AWS credentials**
```bash
aws configure
```

3. **Set up IAM roles**
```bash
cd iam
./setup-iam-roles.sh
```

4. **Create S3 bucket**
```bash
cd ../scripts
./setup_s3_buckets.sh
```

5. **Deploy Lambda**
```bash
cd ../lambda/ingestion
./deploy.sh
```

6. **Deploy Glue jobs** (after Day 3)
```bash
cd ../../glue
./deploy_glue_jobs.sh
```

## 📊 Data Quality Metrics

The platform tracks 4 quality dimensions:

| Metric | Definition | Alert Threshold |
|--------|------------|-----------------|
| **Completeness** | % of mandatory fields populated | < 80% |
| **Consistency** | Schema stability, type validation | Schema changed |
| **Timeliness** | On-time ingestion rate | > 10min late |
| **Overall Quality** | Weighted composite (0-100) | < 80 |

## 📁 Project Structure
```
weather-data-platform/
├── lambda/ingestion/        # Data ingestion with quality checks
├── glue/                    # ETL transformations
├── athena/                  # SQL queries and DDLs
├── iam/                     # IAM roles and policies
├── config/                  # Configuration files
├── scripts/                 # Deployment scripts
└── docs/                    # Documentation
```

## 🔍 Sample Queries

**Find quality issues:**
```sql
SELECT date, overall_quality_score
FROM gold_quality_scorecard_daily
WHERE overall_quality_score < 80
ORDER BY date DESC;
```

**Detect schema drift:**
```sql
SELECT date, schema_version, new_fields
FROM metrics_quality_events
WHERE schema_drift_detected = true;
```

## 📚 Documentation

- [Architecture Details](docs/architecture.md)

## 🎓 Skills Demonstrated

- Serverless architecture (Lambda, Glue, Athena)
- Data quality engineering
- Schema evolution handling
- Cost optimization
- Production monitoring
- Infrastructure as code

## 📝 License

MIT License - see LICENSE file

## 👤 Author

**Suraj Kumar**
[LinkedIn](www.linkedin.com/in/suraj-kumar-0700ba193)