#!/bin/bash

# Spotify Daily Collection Script
# Runs via cron job twice daily

# Load environment variables
source /home/gamarullah/.secrets/spotify

# Navigate to project directory
cd /home/gamarullah/projects/de-project-spotify

# Log file location
LOG_DIR="/home/gamarullah/projects/de-project-spotify/logs"
mkdir -p $LOG_DIR
LOG_FILE="$LOG_DIR/collection_$(date +%Y-%m-%d).log"

echo "======================================" >> $LOG_FILE
echo "Collection started: $(date)" >> $LOG_FILE
echo "======================================" >> $LOG_FILE

# Step 1: Stop Metabase to release DuckDB lock
echo "Stopping Metabase..." >> $LOG_FILE
/usr/bin/docker stop metabase >> $LOG_FILE 2>&1

# Step 2: Run data collection
echo "Running collection..." >> $LOG_FILE
/usr/bin/docker compose run --rm spotify-collector \
  python scripts/collect.py >> $LOG_FILE 2>&1

# Step 3: Run dbt transformations
echo "Running dbt..." >> $LOG_FILE
/usr/bin/docker compose run --rm spotify-collector \
  dbt run --profiles-dir /app --project-dir /app >> $LOG_FILE 2>&1

# Check if dbt succeeded
if [ $? -eq 0 ]; then
    echo "✓ Collection and transformation complete: $(date)" >> $LOG_FILE
else
    echo "✗ dbt FAILED: $(date)" >> $LOG_FILE
fi

# Step 4: Restart Metabase regardless of dbt result
echo "Restarting Metabase..." >> $LOG_FILE
/usr/bin/docker start metabase >> $LOG_FILE 2>&1

echo "======================================" >> $LOG_FILE
