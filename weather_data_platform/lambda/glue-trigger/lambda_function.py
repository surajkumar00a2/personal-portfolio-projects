"""
Lambda function to trigger Glue jobs from EventBridge
Triggered by S3 events via EventBridge

Handles multiple S3 events by checking if job is already running
"""

import json
import boto3
import os
from datetime import datetime, timezone

glue = boto3.client('glue')

def is_job_running(job_name):
    """
    Check if a Glue job is currently running
    
    Returns:
        bool: True if job is running, False otherwise
    """
    try:
        response = glue.get_job_runs(
            JobName=job_name,
            MaxResults=10
        )
        
        # Check if any recent runs are in RUNNING state
        for run in response.get('JobRuns', []):
            state = run.get('JobRunState')
            if state in ['RUNNING', 'STARTING', 'STOPPING']:
                job_run_id = run.get('Id')
                started = run.get('StartedOn')
                print(f"Job {job_name} already running: {job_run_id} (started {started})")
                return True
        
        return False
        
    except Exception as e:
        print(f"Error checking job status: {e}")
        return False


def lambda_handler(event, context):
    """
    Trigger Glue job based on S3 event
    
    Event from EventBridge contains S3 object details
    Implements idempotency - only starts job if not already running
    """
    print(f"Received event: {json.dumps(event)}")
    
    # Extract S3 details from EventBridge event
    try:
        bucket = event['detail']['bucket']['name']
        key = event['detail']['object']['key']
        
        print(f"S3 Event: s3://{bucket}/{key}")
        
        # Determine which Glue job to trigger based on S3 prefix
        if key.startswith('data/bronze/'):
            job_name = os.environ['BRONZE_TO_SILVER_JOB']
            print(f"Bronze data detected - Job to trigger: {job_name}")
            
        elif key.startswith('data/silver/'):
            job_name = os.environ['SILVER_TO_GOLD_JOB']
            print(f"Silver data detected - Job to trigger: {job_name}")
            
        else:
            print(f"Ignoring event for key: {key} (not a trigger path)")
            return {
                'statusCode': 200,
                'body': json.dumps('Event ignored - not a trigger path')
            }
        
        # Check if job is already running (IDEMPOTENCY)
        if is_job_running(job_name):
            print(f"Job {job_name} already running - skipping trigger")
            return {
                'statusCode': 200,
                'body': json.dumps({
                    'message': 'Job already running - skipped',
                    'job_name': job_name,
                    'action': 'skipped'
                })
            }
        
        # Start Glue job
        print(f"Starting Glue job: {job_name}")
        response = glue.start_job_run(
            JobName=job_name,
            Arguments={
                '--S3_BUCKET': bucket,
                '--triggered_by': 's3_event',
                '--s3_key': key,
                '--trigger_time': datetime.now(timezone.utc).isoformat()
            }
        )
        
        job_run_id = response['JobRunId']
        print(f"✓ Started Glue job: {job_name}, RunId: {job_run_id}")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Glue job started successfully',
                'job_name': job_name,
                'job_run_id': job_run_id,
                'action': 'started'
            })
        }
        
    except KeyError as e:
        print(f"Error parsing event: {e}")
        return {
            'statusCode': 400,
            'body': json.dumps(f'Invalid event structure: {e}')
        }
        
    except Exception as e:
        print(f"Error: {e}")
        # Don't raise - return success so EventBridge doesn't retry
        return {
            'statusCode': 500,
            'body': json.dumps({
                'message': f'Error: {str(e)}',
                'action': 'error'
            })
        }