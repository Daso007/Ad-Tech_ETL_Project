IF EXISTS (SELECT * FROM sys.external_tables WHERE name = 'SilverAdPerformance') DROP EXTERNAL TABLE SilverAdPerformance;
IF EXISTS (SELECT * FROM sys.external_file_formats WHERE name = 'SilverParquetFormat') DROP EXTERNAL FILE FORMAT SilverParquetFormat;
IF EXISTS (SELECT * FROM sys.external_data_sources WHERE name = 'SilverDataLake') DROP EXTERNAL DATA SOURCE SilverDataLake;
GO


-- Step 2: Define Data Source and File Format (no changes here).
PRINT 'Step 2 & 3: Creating External Data Source and File Format...';
CREATE EXTERNAL DATA SOURCE SilverDataLake WITH ( LOCATION = '' ); -- **<-- UPDATE YOUR LAKE NAME**
CREATE EXTERNAL FILE FORMAT SilverParquetFormat WITH ( FORMAT_TYPE = PARQUET );
GO


-- Step 4: The Main ETL Operation with the Corrected Parser Settings.
PRINT 'Step 4: Creating the Silver external table from Bronze data...';
CREATE EXTERNAL TABLE SilverAdPerformance
WITH (
    LOCATION = 'ad_performance/',
    DATA_SOURCE = SilverDataLake,
    FILE_FORMAT = SilverParquetFormat
)
AS
SELECT
    j.report_date, j.campaign_id, j.ad_group_id, j.device,
    j.impressions, j.clicks, j.cost_usd, j.conversions
FROM
    OPENROWSET(
        BULK '', -- **<-- UPDATE YOUR LAKE NAME**
        FORMAT = 'CSV',
        PARSER_VERSION = '2.0',
        -- THE CRITICAL FIX: Use a special character that doesn't exist in the file.
        -- This tells the parser "stop trying to find fields" and forces it to read the whole line.
        FIELDTERMINATOR = '0x01',
        FIELDQUOTE = '0x02'
    )
    WITH (
        jsonContent VARCHAR(8000)
    ) AS RawFile
CROSS APPLY OPENJSON(RawFile.jsonContent)
    WITH (
        report_date     DATE            '$.report_date',
        campaign_id     VARCHAR(50)     '$.campaign_id',
        ad_group_id     VARCHAR(50)     '$.ad_group_id',
        device          VARCHAR(20)     '$.device',
        impressions     INT             '$.impressions',
        clicks          INT             '$.clicks',
        cost_usd        DECIMAL(10,2)   '$.cost_usd',
        conversions     INT             '$.conversions'
    ) AS j;
GO


-- Step 5: Verification.
PRINT 'Step 5: SUCCESS! The Silver table has been created. Querying top 10 rows...';
SELECT TOP 10 * FROM SilverAdPerformance;
GO