import json
import random
from datetime import date, timedelta
from faker import Faker
from azure.storage.blob import BlobServiceClient
import io # We will use an in-memory stream

# --- AZURE CONFIGURATION ---
AZURE_CONNECTION_STRING = "DefaultEndpointsProtocol=https;AccountName=adtechsourcesdlake;AccountKey=kX8BSU+8Zp+QQQmf3F1tMN13oiXpViJLtNVlIFeHWls0yE6JEBnyXHPXDfpH7OXeAB4Ue0r5zx/U+AStvTcqGg==;EndpointSuffix=core.windows.net"
CONTAINER_NAME = "bronze"

# --- DATA GENERATION (Unchanged) ---
def generate_daily_performance_data(report_date):
    fake = Faker()
    data = []
    # Using smaller numbers to guarantee file is well under any limits for this final test
    for camp_id in range(1, 6): 
        for ad_group_id_suffix in range(1, 4):
            # Let's reduce records per group just for this test
            for _ in range(10): 
                impressions = random.randint(1000, 10000)
                clicks = int(impressions * random.uniform(0.01, 0.10))
                cost = round(clicks * random.uniform(0.5, 3.0), 2)
                conversions = int(clicks * random.uniform(0.02, 0.08))
                record = {
                    'report_date': report_date.strftime("%Y-%m-%d"),
                    'campaign_id': f"camp_{camp_id}", 'campaign_name': f"Campaign_{camp_id}",
                    'ad_group_id': f"adg_{camp_id}-{ad_group_id_suffix}", 'ad_group_name': "Example Ad Group",
                    'impressions': impressions, 'clicks': clicks, 'cost_usd': cost, 'conversions': conversions,
                    'device': random.choice(['Mobile', 'Desktop', 'Tablet'])
                }
                data.append(record)
    return data

if __name__ == "__main__":
    yesterday = date.today() - timedelta(days=1)
    daily_data = generate_daily_performance_data(yesterday)
    
    file_name = f"ad_performance_ndjson_{yesterday.strftime('%Y_%m_%d')}.json"
    
    # --- THE CRITICAL CHANGE: CONVERT TO NDJSON AND UPLOAD ---
    try:
        # Use an in-memory text buffer (StringIO) to build the file content
        output_stream = io.StringIO()
        for record in daily_data:
            # Convert each dictionary (record) to a JSON string
            json_string = json.dumps(record)
            # Write that string to the buffer, FOLLOWED BY A NEWLINE
            output_stream.write(json_string + '\n')
        
        # Get the full string content from the buffer
        ndjson_content = output_stream.getvalue()

        # Create blob service client and upload
        blob_service_client = BlobServiceClient.from_connection_string(AZURE_CONNECTION_STRING)
        blob_client = blob_service_client.get_blob_client(container=CONTAINER_NAME, blob=file_name)
        
        print(f"Uploading {file_name} as NDJSON to Azure...")
        blob_client.upload_blob(ndjson_content.encode('utf-8'), overwrite=True)
        print("Upload successful!")
        
    except Exception as ex:
        print(f"An exception occurred: {ex}")