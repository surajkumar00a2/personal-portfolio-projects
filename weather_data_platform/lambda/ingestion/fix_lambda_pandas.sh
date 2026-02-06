#!/bin/bash

echo "=========================================="
echo "FIX: Adding pandas/pyarrow via Lambda Layer"
echo "=========================================="
echo ""

cd /lambda/ingestion

# Step 1: Update requirements.txt (remove pandas/pyarrow)
echo "Step 1: Updating requirements.txt..."
cat > requirements.txt <<'EOF'
requests==2.31.0
EOF
echo "✅ Updated requirements.txt"
echo ""

# Step 2: Determine correct layer ARN for your region
echo "Step 2: Getting AWS Data Wrangler Layer ARN..."
AWS_REGION=$(aws configure get region)

case $AWS_REGION in
  us-east-1)
    LAYER_ARN="arn:aws:lambda:us-east-1:336392948345:layer:AWSSDKPandas-Python311:12"
    ;;
  us-east-2)
    LAYER_ARN="arn:aws:lambda:us-east-2:336392948345:layer:AWSSDKPandas-Python311:12"
    ;;
  us-west-1)
    LAYER_ARN="arn:aws:lambda:us-west-1:336392948345:layer:AWSSDKPandas-Python311:12"
    ;;
  us-west-2)
    LAYER_ARN="arn:aws:lambda:us-west-2:336392948345:layer:AWSSDKPandas-Python311:12"
    ;;
  eu-west-1)
    LAYER_ARN="arn:aws:lambda:eu-west-1:336392948345:layer:AWSSDKPandas-Python311:12"
    ;;
  eu-central-1)
    LAYER_ARN="arn:aws:lambda:eu-central-1:336392948345:layer:AWSSDKPandas-Python311:12"
    ;;
  ap-south-1)
    LAYER_ARN="arn:aws:lambda:ap-south-1:336392948345:layer:AWSSDKPandas-Python311:12"
    ;;
  ap-southeast-1)
    LAYER_ARN="arn:aws:lambda:ap-southeast-1:336392948345:layer:AWSSDKPandas-Python311:12"
    ;;
  *)
    echo "❌ Region $AWS_REGION not found in standard list"
    echo "   Find your ARN at: https://aws-sdk-pandas.readthedocs.io/en/stable/layers.html"
    echo "   Then run manually:"
    echo "   aws lambda update-function-configuration --function-name weather-ingestion --layers YOUR_ARN"
    exit 1
    ;;
esac

echo "✅ Using Layer ARN: $LAYER_ARN"
echo "   Region: $AWS_REGION"
echo ""

# Step 3: Add layer to Lambda
echo "Step 3: Adding layer to Lambda function..."
aws lambda update-function-configuration \
  --function-name weather-ingestion \
  --layers $LAYER_ARN

echo "✅ Layer added to Lambda"
echo ""

# Step 4: Redeploy Lambda (without pandas in ZIP)
echo "Step 4: Redeploying Lambda function..."
./deploy.sh

echo ""
echo "=========================================="
echo "FIX COMPLETE!"
echo "=========================================="
echo ""
echo "Test the Lambda:"
echo "  cd ~/weather-data-platform"
echo "  aws lambda invoke --function-name weather-ingestion --payload '{}' response.json"
echo "  cat response.json | jq ."
echo ""