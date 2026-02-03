#!/bin/bash

echo "=========================================="
echo "DEPLOYING GLUE JOBS"
echo "=========================================="
echo ""

# Get configuration
BUCKET_NAME=$(cat ../config/bucket-name.txt)
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=$(aws configure get region)

echo "Configuration:"
echo "  Bucket: $BUCKET_NAME"
echo "  Region: $AWS_REGION"
echo ""

# Upload scripts to S3
echo "Uploading Glue scripts to S3..."
aws s3 cp bronze_to_silver.py s3://$BUCKET_NAME/scripts/
aws s3 cp silver_to_gold.py s3://$BUCKET_NAME/scripts/
echo "✓ Scripts uploaded"
echo ""

# Create or update Bronze→Silver job
echo "Deploying bronze-to-silver-transform job..."
JOB_EXISTS=$(aws glue get-job --job-name bronze-to-silver-transform 2>&1)

if echo "$JOB_EXISTS" | grep -q "EntityNotFoundException"; then
    aws glue create-job \
      --name bronze-to-silver-transform \
      --role arn:aws:iam::${AWS_ACCOUNT_ID}:role/glue-data-transformation-role \
      --command '{
        "Name": "glueetl",
        "ScriptLocation": "s3://'$BUCKET_NAME'/scripts/bronze_to_silver.py",
        "PythonVersion": "3"
      }' \
      --default-arguments '{
        "--job-language": "python",
        "--job-bookmark-option": "job-bookmark-enable",
        "--enable-metrics": "true",
        "--enable-continuous-cloudwatch-log": "true",
        "--S3_BUCKET": "'$BUCKET_NAME'"
      }' \
      --max-retries 1 \
      --timeout 30 \
      --glue-version "4.0" \
      --number-of-workers 2 \
      --worker-type "G.1X"
    echo "✓ Created bronze-to-silver-transform"
else
    aws glue update-job \
      --job-name bronze-to-silver-transform \
      --job-update '{
        "Role": "arn:aws:iam::'${AWS_ACCOUNT_ID}':role/glue-data-transformation-role",
        "Command": {
          "Name": "glueetl",
          "ScriptLocation": "s3://'$BUCKET_NAME'/scripts/bronze_to_silver.py",
          "PythonVersion": "3"
        }
      }'
    echo "✓ Updated bronze-to-silver-transform"
fi
echo ""

# Create or update Silver→Gold job
echo "Deploying silver-to-gold-aggregations job..."
JOB_EXISTS=$(aws glue get-job --job-name silver-to-gold-aggregations 2>&1)

if echo "$JOB_EXISTS" | grep -q "EntityNotFoundException"; then
    aws glue create-job \
      --name silver-to-gold-aggregations \
      --role arn:aws:iam::${AWS_ACCOUNT_ID}:role/glue-data-transformation-role \
      --command '{
        "Name": "glueetl",
        "ScriptLocation": "s3://'$BUCKET_NAME'/scripts/silver_to_gold.py",
        "PythonVersion": "3"
      }' \
      --default-arguments '{
        "--job-language": "python",
        "--job-bookmark-option": "job-bookmark-disable",
        "--enable-metrics": "true",
        "--enable-continuous-cloudwatch-log": "true",
        "--S3_BUCKET": "'$BUCKET_NAME'"
      }' \
      --max-retries 1 \
      --timeout 30 \
      --glue-version "4.0" \
      --number-of-workers 2 \
      --worker-type "G.1X"
    echo "✓ Created silver-to-gold-aggregations"
else
    aws glue update-job \
      --job-name silver-to-gold-aggregations \
      --job-update '{
        "Role": "arn:aws:iam::'${AWS_ACCOUNT_ID}':role/glue-data-transformation-role",
        "Command": {
          "Name": "glueetl",
          "ScriptLocation": "s3://'$BUCKET_NAME'/scripts/silver_to_gold.py",
          "PythonVersion": "3"
        }
      }'
    echo "✓ Updated silver-to-gold-aggregations"
fi
echo ""

echo "=========================================="
echo "DEPLOYMENT COMPLETE"
echo "=========================================="
echo ""
echo "Glue jobs deployed:"
echo "  ✓ bronze-to-silver-transform"
echo "  ✓ silver-to-gold-aggregations"
echo ""
echo "To run jobs:"
echo "  aws glue start-job-run --job-name bronze-to-silver-transform"
echo "  aws glue start-job-run --job-name silver-to-gold-aggregations"
echo ""