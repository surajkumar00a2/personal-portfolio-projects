#!/bin/bash

set -e  # Exit on error

echo "=========================================="
echo "MASTER DEPLOYMENT SCRIPT"
echo "Weather Data Platform"
echo "=========================================="
echo ""

# Check prerequisites
command -v aws >/dev/null 2>&1 || { echo "❌ AWS CLI not installed"; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "❌ Python3 not installed"; exit 1; }

echo "✓ Prerequisites checked"
echo ""

# Get configuration
if [ ! -f config/bucket-name.txt ]; then
    echo "❌ Bucket name not found. Run setup_s3_buckets.sh first"
    exit 1
fi

if [ ! -f config/api-key.txt ]; then
    echo "❌ API key not found. Add your OpenWeatherMap API key to config/api-key.txt"
    exit 1
fi

BUCKET_NAME=$(cat config/bucket-name.txt)
API_KEY=$(cat config/api-key.txt)
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=$(aws configure get region)

echo "Configuration:"
echo "  Bucket: $BUCKET_NAME"
echo "  Region: $AWS_REGION"
echo "  Account: $AWS_ACCOUNT_ID"
echo ""

# Step 1: Deploy Lambda
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 1: Deploying Lambda Function"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cd ../lambda/ingestion
./deploy.sh
cd ../../scripts
echo ""

# Step 2: Deploy Glue Jobs
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 2: Deploying Glue Jobs"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cd ../glue
./deploy_glue_jobs.sh
cd ../scripts
echo ""

# Step 3: Create Glue Workflow
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 3: Creating Glue Workflow"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cd ../glue
WORKFLOW_EXISTS=$(aws glue get-workflow --name weather-data-pipeline 2>&1)
if echo "$WORKFLOW_EXISTS" | grep -q "EntityNotFoundException"; then
    ./create_workflow.sh
else
    echo "Workflow already exists, skipping..."
fi
cd ../scripts
echo ""

# Step 4: Setup Lifecycle Policies
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 4: Configuring S3 Lifecycle Policies"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
./setup_lifecycle_policies.sh
echo ""

# Step 5: Schedule Crawler
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 5: Scheduling Glue Crawler"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
./schedule_crawler.sh
echo ""

# Summary
echo "=========================================="
echo "DEPLOYMENT COMPLETE! 🎉"
echo "=========================================="
echo ""
echo "✅ Lambda function deployed"
echo "✅ Glue jobs deployed (Bronze→Silver, Silver→Gold)"
echo "✅ Glue workflow created"
echo "✅ S3 lifecycle policies configured"
echo "✅ Glue crawler scheduled"
echo ""
echo "Next Steps:"
echo ""
echo "1. Create Athena tables:"
echo "   - Run DDLs from athena/ddl/*.sql in Athena Console"
echo ""
echo "2. Trigger initial data load:"
echo "   aws lambda invoke --function-name weather-ingestion response.json"
echo ""
echo "3. View CloudWatch dashboard:"
echo "   https://console.aws.amazon.com/cloudwatch/home?region=$AWS_REGION#dashboards:name=data-quality-monitoring"
echo ""
echo "4. Monitor Glue workflow:"
echo "   https://console.aws.amazon.com/glue/home?region=$AWS_REGION#/v2/etl-configuration/workflows"
echo ""
EOF