# Ad-Tech_ETL_Project
End-to-End Serverless AdTech ETL Pipeline on Azure
This repository contains the code and architectural documentation for a complete, production-grade data pipeline built entirely on the Azure cloud platform. The project demonstrates a modern, serverless approach to ingesting, transforming, and visualizing advertising performance data.
Table of Contents
Project Goal & Overview
Architecture
Tooling & Technologies
Pipeline Execution Flow
Data Model: The Medallion Architecture
Setup & Deployment
Key Technical Challenges & Solutions
Project Goal & Overview
The primary goal of this project is to build a scalable and automated ETL pipeline that processes daily advertising performance data. It transforms raw, semi-structured JSON source files into a clean, aggregated, and structured format ready for analysis in a BI tool. This mimics a real-world business use case where an organization needs to consolidate marketing data from various platforms into a single source of truth for performance analysis and calculating KPIs like Return on Ad Spend (ROAS).
Architecture
The pipeline is built on a serverless architecture, prioritizing cost-efficiency and scalability. The core components are orchestrated to run sequentially, ensuring data integrity and robust error handling.
Tooling & Technologies
Data Lake: Azure Data Lake Storage (ADLS) Gen2
Transformation Engine: Azure Synapse Analytics - Serverless SQL Pools
Orchestration: Azure Data Factory (ADF)
Data Modeling: Medallion Architecture (Bronze, Silver, Gold layers)
Data Formats: JSON (raw), Parquet (structured/analytical)
Reporting: Microsoft Power BI
Language: T-SQL, Python (for data generation)
Infrastructure as Code: (Mentioned as a future step, good for interviews)
Pipeline Execution Flow
The entire end-to-end process is automated and orchestrated by a single Azure Data Factory pipeline (PL_Daily_Ad_Performance_ETL) that executes a series of dependent activities:
Setup Data Sources (Script Activity): An initial setup script runs to ensure the Synapse database is correctly configured. It creates a MASTER KEY for storing credentials and defines EXTERNAL DATA SOURCE objects that point to the Bronze, Silver, and Gold locations in the data lake, securely authenticating using the Synapse Workspace's Managed Identity.
Delete Old Silver Data (Delete Activity): To ensure idempotency (the ability to re-run the pipeline safely), this step explicitly deletes the physical Parquet files from the previous day's run in the silver/ad_performance directory.
Execute Bronze-to-Silver ETL (Script Activity): The core transformation script runs on the Synapse Serverless SQL Pool. It reads the raw, Newline Delimited JSON (NDJSON) from the Bronze layer, performs cleaning, type casting, de-duplication, and writes the structured, partitioned output as Parquet files to the Silver layer.
Delete Old Gold Data (Delete Activity): Similarly, this step deletes the physical aggregated files from the gold/daily_campaign_performance directory to prepare for the new data.
Execute Silver-to-Gold ETL (Script Activity): A final SQL script reads the clean, partitioned data from the Silver layer, performs GROUP BY aggregations to calculate campaign-level daily totals, and writes the final aggregated Parquet files to the Gold layer.
Data Model: The Medallion Architecture
Bronze Layer (Raw): Located in the bronze container, this layer stores the raw, untouched NDJSON files as they arrive from the source systems. It serves as the immutable "source of truth".
Silver Layer (Cleansed & Conformed): Located in the silver container, this layer contains the cleaned and structured data stored as partitioned Parquet files. All data types are corrected, and basic quality checks are enforced. This layer is ideal for ad-hoc analysis and serves as the source for the Gold layer.
Gold Layer (Aggregated for BI): Located in the gold container, this layer contains highly aggregated and transformed data designed to directly serve specific business use cases. In this project, it's a daily summary of campaign performance, optimized for fast querying by Power BI.
Setup & Deployment
The code in this repository includes:
data_generator/: A Python script (upload_ad_data.py) to generate realistic NDJSON sample data and upload it to the Bronze layer in ADLS.
sql_scripts/:
01-setup_datasources.sql: The T-SQL script used in the first ADF activity.
02-bronze_to_silver.sql: The main transformation logic for the Silver layer.
03-silver_to_gold.sql: The final aggregation logic for the Gold layer.
A production deployment would involve setting up the Azure resources (Synapse, ADF, ADLS) and then deploying the pipeline via ADF's "Publish" feature or through CI/CD with ARM templates.
Key Technical Challenges & Solutions
During development, several real-world challenges were encountered and solved:
Data Ingestion Failure: The initial multi-line JSON source files were incompatible with the OPENROWSET function's row-size limits. This was solved by re-architecting the source data into the Newline Delimited JSON (NDJSON) format, a best practice for big data ingestion.
Complex Security & Permissions: Connecting ADF to Synapse and Synapse to the Data Lake failed due to a complex chain of permission issues. This was resolved by implementing a robust, end-to-end security model using Azure Managed Identities, granting the correct IAM and Synapse RBAC roles, and configuring the Synapse Network Firewall to allow access from trusted Azure services.
Pipeline Idempotency: The pipeline initially failed on its second run because the CREATE EXTERNAL TABLE command cannot overwrite a non-empty directory. The solution was to make the pipeline fully idempotent by adding Delete activities in ADF to programmatically clean up the output from the previous run before executing the transformation logic.
