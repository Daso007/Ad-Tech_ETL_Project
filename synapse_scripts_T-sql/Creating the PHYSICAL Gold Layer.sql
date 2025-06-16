-- ==========================================================
-- FINAL TRANSFORMATION (v2): Creating the PHYSICAL Gold Layer
-- ==========================================================

-- Clean up objects from any previous runs to make this script re-runnable
IF EXISTS (SELECT * FROM sys.external_tables WHERE name = 'GoldDailyCampaignPerformancePhysical') DROP EXTERNAL TABLE GoldDailyCampaignPerformancePhysical;
IF EXISTS (SELECT * FROM sys.external_data_sources WHERE name = 'GoldDataLake') DROP EXTERNAL DATA SOURCE GoldDataLake;
GO


-- Step 1: Create an External Data Source pointing to your 'gold' container
PRINT 'Step 1: Creating External Data Source for the Gold Layer...';
CREATE EXTERNAL DATA SOURCE GoldDataLake
WITH (
    LOCATION = '' -- **<-- UPDATE YOUR LAKE NAME**
);
GO


-- Step 2: Use CETAS to physically write the aggregated data to the Gold layer
PRINT 'Step 2: Creating physical Parquet files in the Gold Layer...';
CREATE EXTERNAL TABLE GoldDailyCampaignPerformancePhysical
WITH (
    LOCATION = 'daily_campaign_performance/', -- This folder will be created inside your 'gold' container
    DATA_SOURCE = GoldDataLake,
    FILE_FORMAT = SilverParquetFormat -- We can reuse the same Parquet format object
)
AS
SELECT
    report_date,
    campaign_id,
    SUM(impressions) as total_impressions,
    SUM(clicks) as total_clicks,
    SUM(cost_usd) as total_cost,
    SUM(conversions) as total_conversions
FROM
    dbo.SilverAdPerformance -- Reading from our clean Silver table
GROUP BY
    report_date,
    campaign_id;
GO


-- ==========================================================
-- FINAL VERIFICATION
-- ==========================================================
PRINT 'SUCCESS! Physical Gold table created. Querying the new table...';
SELECT * FROM dbo.GoldDailyCampaignPerformancePhysical
ORDER BY report_date DESC;