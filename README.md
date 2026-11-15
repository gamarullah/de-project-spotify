# de-project-spotify

A personal end-to-end data engineering pipeline that collects, transforms, and visualizes my Spotify listening history — built on a self-hosted NAS.

## Overview

This project demonstrates a complete DE pipeline using modern open-source tools. Data is collected daily from the Spotify API, stored as raw JSON on a NAS, transformed using dbt + DuckDB, and visualized via a self-hosted Metabase dashboard.

## Architecture

Spotify API
     ↓
Python + Spotipy (collection scripts)
     ↓
Raw JSON storage (NAS)
/raw/recently_played/YYYY-MM-DD.json
/raw/top_tracks/YYYY-MM-DD.json
/raw/top_artists/YYYY-MM-DD.json
/raw/audio_features/YYYY-MM-DD.json
     ↓
dbt transformations
     ↓
DuckDB (analytics layer)
     ↓
Metabase (self-hosted dashboard)

## Data Collected

- Recently played tracks — up to 50 tracks per collection run
- Top tracks — short, medium, and long term rankings
- Top artists — short, medium, and long term rankings
- Audio features — danceability, energy, valence, tempo, and more

Collection runs twice daily via cron job:
- 13:00 WIB (06:00 UTC) — captures morning session
- 23:58 WIB (16:58 UTC) — captures full day

## Tech Stack

Layer            | Tool
-----------------|------------------------------------------
Collection       | Python 3.11, Spotipy
Orchestration    | Cron job
Containerization | Docker, Docker Compose
Storage          | NAS (UGREEN DXP2800), JSON files
Transformation   | dbt-core 1.12, dbt-duckdb
Analytics DB     | DuckDB 1.5.2
Visualization    | Metabase v0.59.4 (self-hosted)
Secret Mgmt      | direnv + ~/.secrets/
Version Control  | Git, GitHub

## dbt Models

models/
├── staging/                      # Raw JSON → clean tabular views
│   ├── stg_recently_played.sql
│   ├── stg_top_tracks.sql
│   ├── stg_top_artists.sql
│   └── stg_audio_features.sql
└── marts/                        # Analytics-ready tables
    ├── dim_tracks.sql
    ├── dim_artists.sql
    ├── dim_albums.sql
    ├── dim_audio_features.sql
    └── fct_listening_history.sql

## Project Structure

de-project-spotify/
├── scripts/
│   ├── auth.py          # Spotify OAuth handling
│   ├── collect.py       # Main collection script
│   └── utils.py         # Helper functions
├── models/              # dbt models (staging + marts)
├── raw/                 # Raw JSON data (gitignored)
├── analytics/           # DuckDB file (gitignored)
├── logs/                # Collection logs (gitignored)
├── Dockerfile           # Python collector image
├── Dockerfile.metabase  # Custom Metabase + DuckDB image
├── docker-compose.yml
├── dbt_project.yml
├── profiles.yml
└── run_collection.sh    # Cron entry point

## Setup

### Prerequisites

- Docker + Docker Compose
- direnv
- Spotify Developer account

### Environment Variables

Create ~/.secrets/spotify:

    export SPOTIFY_CLIENT_ID="your_client_id"
    export SPOTIFY_CLIENT_SECRET="your_client_secret"
    export SPOTIFY_REDIRECT_URI="http://127.0.0.1:8080"
    export SPOTIFY_TOKEN_CACHE="/path/to/.secrets/spotify_token_cache"

Create .envrc in project root:

    source ~/.secrets/spotify

### First Run

    # Authenticate with Spotify (one-time manual OAuth)
    docker compose run --rm spotify-collector python scripts/auth.py

    # Run collection + dbt
    ./run_collection.sh

### Metabase

Access at http://your-nas-ip:3000

Connect to DuckDB:
    Database file: /analytics/spotify_analytics.duckdb

## Project Status

- [x] Phase 1: Spotify API + OAuth authentication
- [x] Phase 2: Collection scripts
- [x] Phase 3: Automated cron job (twice daily)
- [x] Phase 4: dbt transformations (9 models)
- [x] Phase 5: Metabase self-hosted on NAS
- [ ] Phase 6: Dashboard development
