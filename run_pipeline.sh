#!/bin/bash
set -e
trap "echo 'Interrupted. Exiting...'; exit 1" SIGINT SIGTERM

start_time=$(date +%s)
echo "=== Started at $(date '+%Y-%m-%d %H:%M:%S') ==="

# -----------------------------
# Input arguments from run_all.sh
# -----------------------------
VIDEO_PATH="$1"    # Full path to .MP4 file
YEAR="$2"          # e.g., 2025
DATE="$3"          # e.g., 10-27
# -----------------------------

if [ -z "$VIDEO_PATH" ] || [ -z "$YEAR" ] || [ -z "$DATE" ]; then
    echo "Usage: ./run_pipeline.sh <video_path> <year> <date>"
    echo "Example: ./run_pipeline.sh ~/Dropbox/hummingbirds/2025/10-27/video1.MP4 2025 10-27"
    exit 1
fi

if [ ! -f "$VIDEO_PATH" ]; then
    echo "Error: Video file not found at $VIDEO_PATH"
    exit 1
fi

# -----------------------------
# Dataset and paths
# -----------------------------
BASENAME=$(basename "$VIDEO_PATH" .MP4)
DATASET="${YEAR}_${DATE}"
DATASET_DIR="datasets/${DATASET}"
mkdir -p "$DATASET_DIR"

VIDEO_COPY="$DATASET_DIR/${BASENAME}.MP4"
if [ ! -f "$VIDEO_COPY" ]; then
    echo "Copying video into $DATASET_DIR..."
    cp "$VIDEO_PATH" "$VIDEO_COPY"
fi

FRAMES_DIR="$DATASET_DIR/frames"
BOXES_OUT="$DATASET_DIR/bboxes.json"
BACKGROUND_OUT="$DATASET_DIR/mean_background.png"
TRACKED_OUT="$DATASET_DIR/tracked_bboxes.json"
TRACKED_FRAMES_DIR="$DATASET_DIR/tracked_frames"
TRACKED_OUTPUT_VIDEO="${YEAR}_${DATE}_${BASENAME}.mp4"
OUTPUT_VIDEO="$DATASET_DIR/$TRACKED_OUTPUT_VIDEO"
FEEDERS_FILE="$DATASET_DIR/feeder_locations.json"
TIMESTAMP_FILE="$(dirname "$VIDEO_PATH")/start_timestamp.txt"
VISIT_CSV="$DATASET_DIR/visit_data.csv"

# -----------------------------
# Handle start timestamp
# -----------------------------
if [ -f "$TIMESTAMP_FILE" ]; then
    START_TIMESTAMP=$(cat "$TIMESTAMP_FILE" | tr -d '\n' | tr -d '\r')
    echo "Found start timestamp: $START_TIMESTAMP"
else
    echo "Warning: No start_timestamp.txt found for $VIDEO_PATH."
    echo "A timestamp will be requested during the feeder selection step."
    START_TIMESTAMP="00:00:00"
fi

FPS=60

# -----------------------------
# Process pipeline
# -----------------------------
echo "Processing dataset: $DATASET"
echo "Base video: $BASENAME"
echo "------------------------------------"

echo "Extracting all frames..."
rm -rf "$FRAMES_DIR"
python scripts/extract_frames.py \
    --input "$VIDEO_COPY" \
    --output "$FRAMES_DIR" \
    --start 0 \
    --num-frames -1   # <-- -1 means process the full video

echo "Running bird detection..."
python scripts/detect_birds.py \
    --input "$FRAMES_DIR" \
    --output "$DATASET_DIR" \
    --mask_timer

echo "Running tracking..."
python scripts/tracker.py \
    --input "$BOXES_OUT" \
    --output "$DATASET_DIR" \
    --visualize \
    --frames "$FRAMES_DIR"

echo "Creating tracked video..."
python scripts/frames_to_video.py \
    --input "$TRACKED_FRAMES_DIR" \
    --output "$DATASET_DIR" \
    --fps "$FPS" \
    --video_name "$TRACKED_OUTPUT_VIDEO"

echo "Launching feeder selection GUI..."
python scripts/draw_feeders.py --video "$VIDEO_COPY"

# After GUI, recheck timestamp (user may have created one)
if [ -f "$TIMESTAMP_FILE" ]; then
    START_TIMESTAMP=$(cat "$TIMESTAMP_FILE" | tr -d '\n' | tr -d '\r')
fi

echo "Generating visit CSV..."
python scripts/identify_visits.py \
    --tracked "$TRACKED_OUT" \
    --feeders "$FEEDERS_FILE" \
    --start_time "$START_TIMESTAMP" \
    --fps "$FPS"

end_time=$(date +%s)
duration=$((end_time - start_time))
echo "=== Finished at $(date '+%Y-%m-%d %H:%M:%S') ==="
echo "Total runtime: $((duration / 60)) min $((duration % 60)) sec"
echo "Output video: $OUTPUT_VIDEO"
echo "Pipeline completed successfully."
