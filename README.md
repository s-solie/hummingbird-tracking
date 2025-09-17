# It’s a Bird, Not a Plane: Automated Multi-Hummingbird Tracking in Videos

Grace Liu (COS IW 08: CV for Social Good, Spring 2025)  
Advisors: Olga Russakovsky, Sarah Solie  
Supported by the Stoddard Lab at Princeton.

---

## Overview
This repository provides a full pipeline for automated detection and tracking of multiple hummingbirds in videos.  
It extracts frames, detects birds, applies tracking, generates an annotated video, and produces structured visit data (`visit_data.csv`).  

---

## Setup

1. Install the [uv package manager](https://docs.astral.sh/uv/getting-started/installation/).  
2. Install Python 3.11 with uv:  
   ```
   uv python install 3.11
   ```

3. Create a virtual environment:

   ```bash
   uv venv --python 3.11
   ```
4. Activate the environment:

   ```bash
   source ./venv/bin/activate
   ```
5. Clone this repository:

   ```bash
   git clone https://github.com/graceliu1/hummingbird-tracking.git
   cd hummingbird-tracking
   ```
6. Install dependencies:

   ```bash
   uv pip install -r requirements.txt
   ```
7. Make sure dependencies are sync'ed correctly:
   ```
   uv pip sync requirements.txt
   ```
7. Inside `/datasets/`, create a folder named after your video (e.g. `virginia`):

   ```bash
   mkdir datasets/virginia
   ```
8. Place the raw video file inside this folder:

   ```
   datasets/virginia/virginia.MP4
   ```
9. Give the pipeline script executable permissions:

   ```bash
   chmod +x run_pipeline.sh
   ```
10. Run the pipeline:

   ```bash
   ./run_pipeline.sh
   ```

All intermediate and final outputs are written to:

```
/datasets/[VIDEO_NAME]/
```

---

## Outputs

Running the pipeline produces:

* **`mot_[VIDEO_NAME].mp4`** — the tracked output video, with bounding boxes overlayed
* **`visit_data.csv`** — structured hummingbird feeder visit data

Intermediate files include:

* `frames/` — extracted frames
* `bboxes.json` — detected bird bounding boxes
* `tracked_bboxes.json` — tracked bounding boxes
* `mean_background.png` — computed background image
* `tracked_frames/` — frames with tracked birds overlayed
* `feeder_locations.json` — manually annotated feeder positions

---

## Configurable Parameters (`run_pipeline.sh`)

You can adjust several parameters directly in the script to adapt to your dataset:

| Variable               | Description                                                                             | Default              |
| ---------------------- | --------------------------------------------------------------------------------------- | -------------------- |
| `DATASET`              | Name of dataset folder inside `/datasets` (must match video filename, case-insensitive) | `"virginia"`         |
| `START_FRAME`          | First frame index to process                                                            | `0`                  |
| `NUM_FRAMES`           | Number of frames to process (set smaller for testing)                                   | `2000`               |
| `FPS`                  | Frames per second for output video                                                      | `60`                 |
| `START_TIMESTAMP`      | Real-world start time of the video (HH\:MM\:SS) — used for feeder visit timing          | `"08:22:40"`         |
| `TRACKED_OUTPUT_VIDEO` | Name of final tracked video file                                                        | `"mot_virginia.mp4"` |

**Important notes:**

* The raw video must be named `[DATASET].MP4` and placed under `datasets/[DATASET]/`.
* To process a new video, update `DATASET`, `START_TIMESTAMP`, and optionally `NUM_FRAMES` and `FPS`.
* All output files are written under the corresponding `datasets/[DATASET]/` folder.

---

## Example

To process a video named `virginia.MP4` located in `datasets/virginia/`:

1. Update the script:

   ```bash
   DATASET="virginia"
   TRACKED_OUTPUT_VIDEO="mot_virginia.mp4"
   START_TIMESTAMP="07:15:00"
   ```
2. Run:

   ```bash
   ./run_pipeline.sh
   ```
3. Results will appear in:

   ```
   datasets/arizona/mot_virginia.mp4
   datasets/arizona/visit_data.csv
   ```
