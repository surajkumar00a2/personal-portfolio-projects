# Setup Guide

## Prerequisites

### Required
- AWS Account (Free Tier eligible)
- AWS CLI configured (`aws configure`)
- Python 3.11+
- Git

### Optional
- Docker (for local Lambda testing)
- VS Code with AWS Toolkit

---

## Step-by-Step Setup

### 1. Clone Repository
```bash
git clone <your-repo-url>
cd weather-data-platform
```

---

### 2. Get OpenWeatherMap API Key

1. Sign up at https://openweathermap.org/api
2. Verify your email
3. Copy your API key from https://home.openweathermap.org/api_keys
4. Save it:
```bash
echo "your_api_key_here" > config/api-key.txt
```

**Test the API:**
```bash
API_KEY=$(cat config/api-key.txt)
curl "https://api.openweathermap.org/data/2.5/weather?q=London&appid=$API_KEY"
```

You should see JSON weather data.

---

### 3. Configure AWS CLI
```bash
aws configure

# Enter:
# AWS Access Key ID: [your-key]
# AWS Secret Access Key: [your-secret]
# Default region: us-east-1  (or your preferred region)
# Default output format: json
```

**Verify:**
```bash
aws sts get-caller-identity
```

---

### 4. Create IAM Roles
```bash
cd iam
./setup-iam-roles.sh

# Enter your S3 bucket name when prompted (can be anything unique)
# Example: weather-platform-yourname-123
```

**This creates:**
- `lambda-weather-ingestion-role`
- `glue-data-transformation-role`
- `glue-crawler-role`

---

### 5. Create S3 Bucket
```bash
cd ../scripts
./setup_s3_buckets.sh
```

**This creates:**
- S3 bucket with unique name
- Folder structure (bronze, silver, gold, metrics)
- Saves bucket name to `config/bucket-name.txt`

---

### 6. Deploy Everything

**Option A: One-Click Deployment** (Recommended)
```bash
cd scripts
./deploy_all.sh
```

This deploys:
- Lambda function
- Glue jobs
- Glue workflow
- S3 lifecycle policies
- Glue crawler schedule

**Option B: Manual Step-by-Step**
```bash
# Deploy Lambda
cd lambda/ingestion
./deploy.sh
cd ../..

# Deploy Glue jobs
cd glue
./deploy_glue_jobs.sh
cd ..

# Create workflow
cd glue
./create_workflow.sh
cd ..

# Setup lifecycle policies
cd scripts
./setup_lifecycle_policies.sh
./schedule_crawler.sh
cd ..
```

---

### 7. Create Athena Tables

1. Go to Athena Console: https://console.aws.amazon.com/athena/
2. Select database: `weather_data_lake`
3. Run these DDLs:
```bash
# In Athena Query Editor, copy and run:
athena/ddl/silver_tables.sql
athena/ddl/gold_tables.sql
athena/ddl/metrics_tables.sql
```

4. Create views:
```bash
athena/views/common_views.sql
```

---

### 8. Trigger Initial Data Load
```bash
# Manually trigger Lambda
aws lambda invoke \
  --function-name weather-ingestion \
  --payload '{}' \
  --cli-binary-format raw-in-base64-out \
  response.json

# Check response
cat response.json | jq .
```

**Wait 2-3 minutes, then check S3:**
```bash
BUCKET_NAME=$(cat config/bucket-name.txt)
aws s3 ls s3://$BUCKET_NAME/data/bronze/ --recursive
aws s3 ls s3://$BUCKET_NAME/metrics/quality/ --recursive
```

You should see JSON and Parquet files!

---

### 9. Run Glue Jobs Manually (Optional)
```bash
# Trigger Bronze→Silver
aws glue start-job-run --job-name bronze-to-silver-transform

# Wait ~5 minutes, then trigger Silver→Gold
aws glue start-job-run --job-name silver-to-gold-aggregations

# Run crawler to discover tables
aws glue start-crawler --name weather-data-lake-crawler
```

**Or wait for automatic execution:**
- Lambda runs every 6 hours
- Glue workflow triggers 30min after Lambda
- Crawler runs daily at 04:00 UTC

---

### 10. Query Data in Athena
```sql
-- Check Silver data
SELECT COUNT(*) FROM weather_data_lake.silver_weather_data;

-- Check Gold data
SELECT * FROM weather_data_lake.gold_weather_daily_summary
ORDER BY date DESC LIMIT 10;

-- Check quality
SELECT * FROM weather_data_lake.v_recent_quality_issues;
```

---

## Verification Checklist

Run this verification:
```bash
cd scripts
./verify_deployment.sh
```

**Manual checks:**

- [ ] Lambda function exists and can be invoked
- [ ] Data appears in Bronze layer (JSON files)
- [ ] Metrics appear in quality folder (Parquet files)
- [ ] Glue jobs exist (bronze-to-silver, silver-to-gold)
- [ ] Glue workflow created
- [ ] Athena tables queryable
- [ ] CloudWatch dashboard visible
- [ ] S3 lifecycle policies configured

---

## Troubleshooting

### Lambda fails with "Module not found"
**Solution**: Redeploy Lambda
```bash
cd lambda/ingestion
./deploy.sh
```

### Glue job fails with timestamp error
**Solution**: Check `glue/TROUBLESHOOTING.md`

### Athena returns zero rows
**Solution**: Run crawler or manually add partitions
```sql
MSCK REPAIR TABLE weather_data_lake.silver_weather_data;
```

### API key invalid
**Solution**: Update Lambda environment variable
```bash
aws lambda update-function-configuration \
  --function-name weather-ingestion \
  --environment Variables="{S3_BUCKET=$(cat config/bucket-name.txt),OPENWEATHER_API_KEY=your_new_key}"
```

---

## Next Steps

1. **Monitor**: Check CloudWatch dashboard daily
2. **Analyze**: Run Athena queries from `athena/queries/`
3. **Optimize**: Review costs in AWS Cost Explorer
4. **Extend**: Add more cities, increase frequency, add alerts

---

## Cost Estimates

| Usage | Monthly Cost |
|-------|--------------|
| Current (3 cities, 4x/day) | $1.61 |
| Scaled (10 cities, 24x/day) | $15.00 |
| Production (100 cities, 24x/day) | $40.00 |

**Still 95% cheaper than EC2-based solution!**

