#!/bin/bash
# =====================================================
# run_all.sh
# Recursively processes all .MP4 videos under a given
# root directory using run_pipeline.sh.
# Usage: ./run_all.sh <path_to_data_root>
# Example usage: ./run_all.sh /Volumes/stoddard/HummingbirdVisionVideos/2023/tracking_test
# =====================================================

set -e
trap "echo 'Interrupted. Exiting...'; exit 1" SIGINT SIGTERM

# -----------------------------
# Input
# -----------------------------
DATA_ROOT="$1"

if [ -z "$DATA_ROOT" ]; then
    echo "Usage: $0 <path_to_data_root>"
    exit 1
fi

# Resolve full path
DATA_ROOT=$(cd "$DATA_ROOT" && pwd)

# Check that the directory exists
if [ ! -d "$DATA_ROOT" ]; then
    echo "Error: Directory not found: $DATA_ROOT"
    exit 1
fi

echo "Starting batch processing in: $DATA_ROOT"
echo "--------------------------------------"

# -----------------------------
# Loop over all .MP4 files
# -----------------------------
find "$DATA_ROOT" -type f -name "*.MP4" | sort | while read -r video; do
    # Extract year and date from folder structure:
    # e.g., .../2025/10-27/video1.MP4
    YEAR=$(basename "$(dirname "$(dirname "$video")")")
    DATE=$(basename "$(dirname "$video")")

    # Basic validation
    if [[ ! "$YEAR" =~ ^[0-9]{4}$ ]]; then
        echo "Warning: Skipping $video because YEAR could not be determined from path."
        continue
    fi

    if [[ ! "$DATE" =~ ^[0-9]{2}-[0-9]{2}$ ]]; then
        echo "Warning: Skipping $video because DATE could not be determined from path."
        continue
    fi

    echo "=== Processing video: $video ==="
    ./run_pipeline.sh "$video" "$YEAR" "$DATE"

    echo "--------------------------------------"
done

echo "Batch processing complete!"
