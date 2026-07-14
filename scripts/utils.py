import os
import json
from datetime import datetime, timezone
from pathlib import Path


def get_project_root():
    """Returns the project root directory"""
    return Path(__file__).parent.parent


def get_raw_path(data_type: str, date: str = None) -> Path:
    """
    Returns path for raw data storage.
    
    Args:
        data_type: 'recently_played', 'top_tracks', 'audio_features'
        date: date string YYYY-MM-DD (defaults to today)
    """
    if date is None:
        date = datetime.now().strftime('%Y-%m-%d')
    
    path = get_project_root() / 'raw' / data_type
    path.mkdir(parents=True, exist_ok=True)
    
    return path / f"{date}.json"


def save_json(data: dict, filepath: Path) -> None:
    """Save data as JSON with metadata"""
    output = {
        "collected_at": datetime.now(timezone.utc).isoformat(),
        "data": data
    }
    
    with open(filepath, 'w') as f:
        json.dump(output, f, indent=2)
    
    print(f"Saved: {filepath}")


def load_json(filepath: Path) -> dict:
    """Load JSON data from file"""
    with open(filepath, 'r') as f:
        return json.load(f)


def file_exists_for_today(data_type: str) -> bool:
    """Check if already collected this data type today"""
    filepath = get_raw_path(data_type)
    return filepath.exists()
