# Dataset Preparation Guide

To use the `train.py` scripts with real data from Kaggle, you need to organize the downloaded images and CSVs as follows:

## 1. Image Classification Data
**Location**: `ml_training/image_model/data/`

Structure your files into these subdirectories. The `train.py` script automatically uses folder names as labels:

```
ml_training/image_model/data/
├── road_damage/          <-- Images from Dataset 1 & 4
├── waste_overflow/       <-- Images from Dataset 3
└── streetlight_failure/  <-- Images from Dataset 2 & 4
```

### How to use:
```bash
python ml_training/image_model/train.py --data_dir ml_training/image_model/data/ --epochs 20
```

## 2. Text Classification Data
**Location**: `ml_training/text_model/data.csv`

Create a CSV with the following columns:
- `text`: The issue description.
- `severity`: Integer (0: low, 1: medium, 2: high, 3: critical).
- `department`: Integer (0: road, 1: waste, 2: lights).

### How to use:
```bash
python ml_training/text_model/train.py --csv ml_training/text_model/data.csv
```

## Dataset Mapping (Recommended)
Based on your provided links:
- **Road Damage**: Use Dataset 1 for raw images.
- **Waste**: Use Dataset 3 for raw images.
- **Text/Multi-class**: Use Dataset 2 and 4 to extract labels and descriptions.
