#!/bin/bash

# Spotify Daily Collection Script
# Runs via cron job daily

# Load environment variables
source /home/gamarullah/.secrets/spotify

# Navigate to project directory
cd /home/gamarullah/projects/spotify

# Log file location
LOG_DIR="/home/gamarullah/projects/spotify/logs"
mkdir -p $LOG_DIR
LOG_FILE="$LOG_DIR/collection_$(date +%Y-%m-%d).log"

echo "======================================" >> $LOG_FILE
echo "Collection started: $(date)" >> $LOG_FILE
echo "======================================" >> $LOG_FILE

# Run Docker collection using full path
/usr/bin/docker compose run --rm spotify-collector \
  python scripts/collect.py >> $LOG_FILE 2>&1

# Check if successful
if [ $? -eq 0 ]; then
    echo "✓ Collection completed successfully: $(date)" >> $LOG_FILE
else
    echo "✗ Collection FAILED: $(date)" >> $LOG_FILE
fi

echo "======================================" >> $LOG_FILE
