CREATE VIEW GoldDailyCampaignPerformance
AS
SELECT
    report_date,
    campaign_id,
    SUM(impressions) as total_impressions,
    SUM(clicks) as total_clicks,
    SUM(cost_usd) as total_cost,
    SUM(conversions) as total_conversions
FROM
    dbo.SilverAdPerformance
GROUP BY
    report_date,
    campaign_id;
GO -- It's good practice to end scripts with GO.


-- BATCH 3: Verification Logic
PRINT 'SUCCESS! Gold view created. Now querying the final aggregated data...';
SELECT
    *
FROM
    dbo.GoldDailyCampaignPerformance
ORDER BY
    report_date DESC;
GO