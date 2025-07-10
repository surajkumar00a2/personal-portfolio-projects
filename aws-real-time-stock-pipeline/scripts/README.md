# AWS Stock Market Data Pipeline with Power BI

A real-time stock market data processing pipeline built on AWS Free Tier services with Power BI visualization. This project demonstrates how to ingest, process, and visualize streaming stock market data using modern cloud technologies.

## 🏗️ Architecture Overview

The pipeline processes real-time stock market data through the following components:

### Key Components:
- **Data Source**: Alpha Vantage API for real-time stock market data
- **Data Ingestion**: AWS Kinesis for streaming data ingestion
- **Data Processing**: PySpark on AWS Glue or EMR for distributed processing
- **Data Storage**: AWS S3 for raw and processed data storage
- **Querying**: AWS Athena for SQL-based analytics
- **Visualization**: Power BI for interactive dashboards

## 🛠️ Technologies Used

- **PySpark**: Distributed data processing
- **AWS Kinesis**: Real-time data streaming
- **AWS S3**: Object storage for data lake
- **AWS Glue**: Serverless ETL processing
- **AWS EMR**: Managed Hadoop framework (alternative to Glue)
- **AWS Athena**: Serverless SQL queries
- **Power BI**: Data visualization and dashboards
- **Python**: Data collection and processing scripts
- **Alpha Vantage API**: Stock market data provider

## 📋 Prerequisites

- AWS Account with Free Tier access
- Alpha Vantage API key (free tier available)
- Power BI Desktop installed
- Python 3.7+ with boto3 library
- Basic knowledge of AWS services, PySpark, and SQL

## 🚀 Getting Started

### Step 1: AWS Environment Setup

**IAM Role Configuration**
- Create an IAM role with policies for S3, Kinesis, Glue, and Athena access
- Attach `AmazonS3FullAccess`, `AmazonKinesisFullAccess`, `AWSGlueServiceRole`, and `AmazonAthenaFullAccess`

**S3 Bucket Setup**
- Create an S3 bucket for storing raw and processed data
- Organize folders for `raw-data/` and `processed-data/`

**Kinesis Stream Setup**
- Create a Kinesis data stream named `StockDataStream`
- Start with 1 shard for simplicity
- Configure partition keys for efficient data distribution

### Step 2: Alpha Vantage API Setup

**API Access**
- Sign up at Alpha Vantage for free API access
- Obtain your API key for accessing stock market data
- Test the TIME_SERIES_INTRADAY endpoint for real-time data

**Data Understanding**
- Review API response structure (symbol, price, volume, timestamp)
- Plan data transformation requirements for downstream processing

### Step 3: Data Ingestion with Kinesis

**Stream Configuration**
- Configure Kinesis stream in AWS Management Console
- Set up appropriate shard count based on expected data volume
- Understand partition key strategy for load balancing

**Data Collection**
- Create Python scripts to fetch data from Alpha Vantage API
- Implement data ingestion to Kinesis using boto3 library
- Format data as JSON for consistent processing

### Step 4: Data Processing with PySpark

**Processing Environment Setup**
- **Option A: AWS Glue** - Serverless ETL with managed infrastructure
- **Option B: AWS EMR** - Customizable Spark cluster environment

**Data Processing Tasks**
- Connect PySpark job to Kinesis stream
- Implement data cleaning (remove nulls, handle malformed data)
- Calculate financial metrics (moving averages, price changes)
- Aggregate data for analytical queries

**Data Output**
- Write processed data to S3 in optimized formats (Parquet/JSON)
- Implement partitioning strategy for efficient querying
- Set up data lifecycle management policies

### Step 5: Analytics with AWS Athena

**Athena Configuration**
- Create database for stock data analytics
- Define external tables pointing to processed data in S3
- Set up table schemas matching processed data structure

**Query Development**
- Develop SQL queries for stock trend analysis
- Create views for common analytical patterns
- Optimize queries for performance and cost efficiency

### Step 6: Visualization with Power BI

**Power BI Setup**
- Install Power BI Desktop
- Configure AWS Athena connector for Power BI
- Set up ODBC driver for Athena connectivity

**Dashboard Development**
- Create line charts for stock price trends over time
- Build bar charts for trading volume comparisons
- Develop heatmaps for price movement visualization
- Design interactive filters for symbol and time period selection

**Dashboard Features**
- Real-time data refresh capabilities
- Multi-symbol comparison views
- Technical indicator visualizations
- Performance metrics and KPIs

## 📊 Data Flow

1. **Data Collection**: Python scripts fetch real-time stock data from Alpha Vantage API
2. **Stream Ingestion**: Stock data is sent to AWS Kinesis for real-time processing
3. **Data Processing**: PySpark jobs on Glue/EMR clean and transform the streaming data
4. **Data Storage**: Processed data is stored in S3 with optimized partitioning
5. **Data Querying**: Athena provides SQL interface for analytical queries
6. **Visualization**: Power BI creates interactive dashboards from processed data

## 🔧 Configuration

### Environment Variables
- `AWS_REGION`: AWS region for your resources
- `ALPHA_VANTAGE_API_KEY`: Your Alpha Vantage API key
- `S3_BUCKET_NAME`: Name of your S3 bucket
- `KINESIS_STREAM_NAME`: Name of your Kinesis stream

### AWS Resource Configuration
- Kinesis shard count based on data volume
- S3 bucket lifecycle policies for cost optimization
- Glue/EMR instance types within Free Tier limits
- Athena query result location configuration

## 🚦 Testing and Validation

### Component Testing
- Test Alpha Vantage API connectivity and data retrieval
- Validate Kinesis stream ingestion and data flow
- Verify PySpark job processing and S3 output
- Confirm Athena table creation and query execution
- Test Power BI connectivity and dashboard functionality

### Performance Monitoring
- Monitor Kinesis stream metrics and throughput
- Track Glue/EMR job execution times and resource usage
- Analyze Athena query performance and costs
- Validate Power BI dashboard refresh times

## 📈 Features

### Real-time Processing
- Continuous data ingestion from stock market APIs
- Stream processing with configurable batch intervals
- Near real-time dashboard updates

### Financial Analytics
- Moving averages calculation (SMA, EMA)
- Price change percentage tracking
- Volume-weighted average price (VWAP)
- High/low price analysis

### Scalable Architecture
- Horizontal scaling through Kinesis shards
- Distributed processing with PySpark
- Cost-effective storage with S3 lifecycle policies
- Serverless querying with Athena

## 🔍 Monitoring and Optimization

### AWS CloudWatch Integration
- Monitor Kinesis stream metrics
- Track Glue/EMR job performance
- Set up alarms for pipeline failures

### Cost Optimization
- Implement S3 lifecycle policies
- Optimize Athena query patterns
- Monitor Free Tier usage limits
- Use spot instances for EMR when applicable

## 📝 Documentation

### Project Structure
- `/scripts/`: Python scripts for data collection and processing
- `/pyspark-jobs/`: PySpark job definitions for Glue/EMR
- `/athena-queries/`: SQL queries for data analysis
- `/power-bi/`: Power BI dashboard templates and configurations
- `/cloudformation/`: Infrastructure as Code templates

### Additional Resources
- Alpha Vantage API documentation
- AWS service documentation links
- Power BI connector setup guides
- Troubleshooting common issues

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues, feature requests, or pull requests to improve the pipeline.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Alpha Vantage for providing free stock market data API
- AWS for Free Tier services enabling cost-effective cloud development
- Power BI for powerful data visualization capabilities
