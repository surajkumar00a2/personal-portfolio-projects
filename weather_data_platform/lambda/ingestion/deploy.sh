#!/bin/bash

echo "=========================================="
echo "DEPLOYING LAMBDA INGESTION FUNCTION"
echo "=========================================="
echo ""

# Get config
BUCKET_NAME=$(cat ../../config/bucket-name.txt)
API_KEY=$(cat ../../config/api-key.txt)
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=$(aws configure get region)

echo "Configuration:"
echo "  Bucket: $BUCKET_NAME"
echo "  Region: $AWS_REGION"
echo ""

# Create package
echo "Creating deployment package..."
mkdir -p package
cd package

pip install -r ../requirements.txt -t . -q

cp ../lambda_ingestion_v2.py .
cp ../quality_validator.py .
cp ../schema_definition.py .

zip -r ../lambda_deployment.zip . -q

cd ..
rm -rf package

echo "✓ Package created"
echo ""

# Check if Lambda exists
LAMBDA_EXISTS=$(aws lambda get-function --function-name weather-ingestion 2>&1)

if echo "$LAMBDA_EXISTS" | grep -q "ResourceNotFoundException"; then
    echo "Creating new Lambda function..."
    
    aws lambda create-function \
      --function-name weather-ingestion \
      --runtime python3.11 \
      --role arn:aws:iam::${AWS_ACCOUNT_ID}:role/lambda-weather-ingestion-role \
      --handler lambda_ingestion_v2.lambda_handler \
      --zip-file fileb://lambda_deployment.zip \
      --timeout 120 \
      --memory-size 512 \
      --environment Variables="{S3_BUCKET=$BUCKET_NAME,OPENWEATHER_API_KEY=$API_KEY}" \
      --description "Weather data ingestion with quality monitoring"
    
    echo "✓ Lambda function created"
else
    echo "Updating existing Lambda function..."
    
    aws lambda update-function-code \
      --function-name weather-ingestion \
      --zip-file fileb://lambda_deployment.zip -q
    
    aws lambda update-function-configuration \
      --function-name weather-ingestion \
      --handler lambda_ingestion_v2.lambda_handler \
      --timeout 120 \
      --memory-size 512 \
      --environment Variables="{S3_BUCKET=$BUCKET_NAME,OPENWEATHER_API_KEY=$API_KEY}" -q
    
    echo "✓ Lambda function updated"
fi

echo ""
echo "=========================================="
echo "DEPLOYMENT COMPLETE"
echo "=========================================="
