Python 3.14.0 (main, Oct  7 2025, 09:34:52) [Clang 17.0.0 (clang-1700.0.13.3)] on darwin
Enter "help" below or click "Help" above for more information.
>>> #!/bin/bash
... set -e
... trap "echo 'Interrupted. Exiting...'; exit 1" SIGINT SIGTERM
... 
... # Usage: ./run_all.sh <directory>
... # Example: ./run_all.sh ~/Library/CloudStorage/Dropbox/hummingbirds/
... 
... INPUT_DIR="$1"
... 
... if [ -z "$INPUT_DIR" ]; then
...     echo "Usage: ./run_all.sh <directory containing videos>"
...     echo "Example: ./run_all.sh ~/Library/CloudStorage/Dropbox/hummingbirds/"
...     exit 1
... fi
... 
... if [ ! -d "$INPUT_DIR" ]; then
...     echo "Error: Directory not found — $INPUT_DIR"
...     exit 1
... fi
... 
... echo "=== Starting batch processing for: $INPUT_DIR ==="
... start_time=$(date +%s)
... 
... # Recursively find all .MP4 files
... find "$INPUT_DIR" -type f \( -iname "*.mp4" -o -iname "*.MP4" \) | while read -r video; do
...     echo "-----------------------------------------------------"
...     echo "Found video: $video"
... 
...     # Extract relative parts of the path to make a unique dataset name
...     # e.g., Dropbox/hummingbirds/2024/06-01/camA.MP4 → 2024_06-01_camA
...     year=$(basename "$(dirname "$(dirname "$video")")")
...     date=$(basename "$(dirname "$video")")
...     base=$(basename "$video" .MP4)
...     base=$(basename "$base" .mp4)
... 
...     # Handle shallow folder structures
    if [ "$year" = "$(basename "$INPUT_DIR")" ]; then
        dataset="${date}_${base}"
    else
        dataset="${year}_${date}_${base}"
    fi

    # Clean up name (replace spaces and slashes)
    dataset=$(echo "$dataset" | tr ' /' '__')

    # Create a dataset folder inside hummingbird-tracking/datasets
    dataset_dir="datasets/$dataset"
    mkdir -p "$dataset_dir"

    # Skip already-processed datasets
    if [ -f "$dataset_dir/mot_${dataset}.mp4" ]; then
        echo "⏩ Skipping $dataset — already processed."
        continue
    fi

    # Symlink the video into hummingbird-tracking (no duplication)
    ln -sf "$(realpath "$video")" "$dataset_dir/${dataset}.MP4"

    echo "Created dataset: $dataset_dir"
    echo "→ Linked video: ${dataset}.MP4"

    # Run the single-video pipeline
    ./run_pipeline.sh "$dataset"

    echo "✅ Finished processing: $dataset"
    echo
done

end_time=$(date +%s)
duration=$((end_time - start_time))
echo "=== All videos processed ==="
echo "Total runtime: $((duration / 60)) min $((duration % 60)) sec"
