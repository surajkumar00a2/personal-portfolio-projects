#!/bin/bash

echo "=========================================="
echo "DEPLOYING GLUE TRIGGER LAMBDA"
echo "=========================================="
echo ""

AWS_REGION=$(aws configure get region)
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Create IAM role for Lambda
echo "1. Creating IAM role for Glue trigger Lambda..."

cat > /tmp/lambda-glue-trigger-trust.json <<TRUST
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
TRUST

cat > /tmp/lambda-glue-trigger-policy.json <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:$AWS_REGION:$ACCOUNT_ID:*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "glue:StartJobRun",
        "glue:GetJobRun",
        "glue:GetJobRuns"
      ],
      "Resource": [
        "arn:aws:glue:$AWS_REGION:$ACCOUNT_ID:job/bronze-to-silver-transform",
        "arn:aws:glue:$AWS_REGION:$ACCOUNT_ID:job/silver-to-gold-aggregations"
      ]
    }
  ]
}
POLICY

# Create role
aws iam create-role \
  --role-name lambda-glue-trigger-role \
  --assume-role-policy-document file:///tmp/lambda-glue-trigger-trust.json \
  --description "Role for Lambda to trigger Glue jobs" 2>/dev/null || \
  echo "  Role already exists, updating policy..."

# Attach policy
aws iam put-role-policy \
  --role-name lambda-glue-trigger-role \
  --policy-name GlueTriggerPolicy \
  --policy-document file:///tmp/lambda-glue-trigger-policy.json

LAMBDA_ROLE_ARN="arn:aws:iam::$ACCOUNT_ID:role/lambda-glue-trigger-role"

echo "✓ IAM role created"
echo ""

# Wait for role to propagate
echo "Waiting for IAM role to propagate..."
sleep 10

# Package Lambda function
echo "2. Packaging Lambda function..."
cd lambda/glue-trigger
zip -q lambda.zip lambda_function.py
cd ../..

echo "✓ Lambda packaged"
echo ""

# Create/update Lambda function
echo "3. Creating Lambda function..."

LAMBDA_EXISTS=$(aws lambda get-function --function-name glue-job-trigger 2>&1)

if echo "$LAMBDA_EXISTS" | grep -q "FunctionName"; then
    echo "  Updating existing function..."
    aws lambda update-function-code \
      --function-name glue-job-trigger \
      --zip-file fileb://lambda/glue-trigger/lambda.zip
    
    aws lambda update-function-configuration \
      --function-name glue-job-trigger \
      --environment "Variables={
        BRONZE_TO_SILVER_JOB=bronze-to-silver-transform,
        SILVER_TO_GOLD_JOB=silver-to-gold-aggregations
      }"
else
    echo "  Creating new function..."
    aws lambda create-function \
      --function-name glue-job-trigger \
      --runtime python3.11 \
      --role $LAMBDA_ROLE_ARN \
      --handler lambda_function.lambda_handler \
      --zip-file fileb://lambda/glue-trigger/lambda.zip \
      --timeout 60 \
      --memory-size 128 \
      --environment "Variables={
        BRONZE_TO_SILVER_JOB=bronze-to-silver-transform,
        SILVER_TO_GOLD_JOB=silver-to-gold-aggregations
      }"
fi

echo "✓ Lambda function deployed"
echo ""

# Clean up
rm lambda/glue-trigger/lambda.zip
rm /tmp/lambda-glue-trigger-*.json

echo "=========================================="
echo "GLUE TRIGGER LAMBDA DEPLOYED"
echo "=========================================="
echo ""
echo "Function: glue-job-trigger"
echo "Role: $LAMBDA_ROLE_ARN"
echo ""
