# Spotify DE Project

Personal data engineering pipeline that collects and analyzes my Spotify listening history.

## Tech Stack
- **Ingestion**: Python + Spotipy
- **Storage**: NAS (UGREEN DXP2800)
- **Transformation**: dbt + DuckDB
- **Visualization**: UNDECIDED
- **Orchestration**: Cron job (daily)
- **Infrastructure**: Docker

## Architecture
Spotify API → Python Collection Script → Raw JSON (NAS) → dbt transformations → DuckDB → UDECIDED Dashboard

## Data Collected
- Recently played tracks (daily, 50 tracks)
- Top tracks across 3 time ranges
- Top artists across 3 time ranges

## Project Status
- [x] Phase 1: API setup + authentication
- [x] Phase 2: Collection scripts
- [x] Phase 3: Daily automated collection
- [ ] Phase 4: dbt transformations
- [ ] Phase 5: DuckDB analytics layer
- [ ] Phase 6: Dashboarding

## Setup
See `.env.example` for required environment variables.
Credentials managed via direnv + `~/.secrets/`.
