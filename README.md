# de-project-spotify

A personal end-to-end data engineering pipeline that collects, transforms, and visualizes my Spotify listening history, self-hosted on a NAS.

## Overview

Data is collected twice a day from the Spotify Web API, stored as immutable-ish raw JSON on a NAS, transformed with dbt + DuckDB into a small dimensional model, and visualized in a self-hosted Metabase instance. All Python and dbt execution runs inside Docker, because the NAS operating system (UGOS) locks down system Python and build tools.

## Architecture

    Spotify Web API
          |
    Python + Spotipy  (Docker, scheduled by cron)
          |
    Raw JSON on NAS   raw/<type>/YYYY-MM-DD.json   (UTC timestamps)
          |
    dbt (staging views -> dimension tables + incremental fact)
          |
    DuckDB            analytics/spotify_analytics.duckdb
          |
    Metabase          (self-hosted, reachable over Tailscale)

## Data Collected

- Recently played tracks (last 50 per run)
- Top tracks: short, medium and long term
- Top artists: short, medium and long term
- Audio features for recently played tracks (availability depends on the Spotify API; the collector skips it on HTTP 403)

Schedule (cron, system clock in UTC):

- 06:00 UTC (13:00 WIB): midday snapshot
- 16:58 UTC (23:58 WIB): end-of-day snapshot

A same-day rerun overwrites that day's file, so the last run of the day wins.

## Tech Stack

| Layer              | Tool                                              |
|--------------------|---------------------------------------------------|
| Collection         | Python (python:latest image), Spotipy             |
| Scheduling         | cron via /etc/cron.d                              |
| Containerization   | Docker, Docker Compose                            |
| Storage            | UGREEN DXP2800 NAS, JSON files                    |
| Transformation     | dbt-core 1.12, dbt-duckdb 1.10, dbt_utils 1.4     |
| Analytics DB       | DuckDB 1.5.2 (pinned to match the Metabase driver)|
| Visualization      | Metabase v0.59.4 + MotherDuck DuckDB driver 1.5.2 |
| Secrets            | direnv + ~/.secrets (outside the repo)            |
| Remote access      | Tailscale                                         |

## dbt Models

    models/
    +-- staging/                     views, read raw JSON via read_json()
    |   +-- stg_recently_played.sql
    |   +-- stg_top_tracks.sql
    |   +-- stg_top_artists.sql
    |   +-- stg_audio_features.sql
    +-- marts/
        +-- dim_tracks.sql           table, one row per track_id
        +-- dim_artists.sql          table, one row per artist_id
        +-- dim_albums.sql           table, one row per album_id
        +-- dim_audio.sql            table, optional (sparse) track attributes
        +-- fct_listening_history.sql  incremental, one row per listening event
        +-- schema.yml               data tests

Design notes:

- Casting and cleanup happen once, in staging. Marts inherit clean types.
- All timestamps stay in UTC. Local-time (WIB) columns belong in the transform layer and are not modeled yet.
- Spotify returns partial release dates ("2001", "2001-09"). The pipeline keeps release_date as DATE only when it is a full date and derives release_year separately, rather than inventing a month or day.
- Dimensions are deduplicated with QUALIFY ROW_NUMBER(), keeping the most recently collected row per key.
- fct_listening_history is incremental on played_at, with the intended unique key (played_at, track_id, context_type).
- Reserved words are renamed at staging (rank -> artist_rank / track_rank, key -> musical_key).

## Data Tests

- unique + not_null on the primary key of each dimension
- not_null on played_at and track_id in the fact table
- a unique-combination test on (played_at, track_id, context_type)
- a singular test that fails if no data has been collected for 12 hours

Status: the unique-combination test on fct_listening_history is currently failing (138 duplicate keys) and is being investigated.

## Project Structure

    de-project-spotify/
    +-- scripts/
    |   +-- auth.py            Spotify OAuth client
    |   +-- collect.py         collectors for each data type
    |   +-- utils.py           paths and JSON helpers
    +-- models/                dbt models and schema.yml
    +-- tests/                 dbt singular tests
    +-- dbt_project.yml
    +-- profiles.yml
    +-- packages.yml           dbt_utils
    +-- Dockerfile             collector + dbt image
    +-- Dockerfile.metabase    Metabase + DuckDB driver image
    +-- docker-compose.yml
    +-- run_collection.sh      cron entry point
    +-- raw/                   private data, gitignored
    +-- analytics/             DuckDB file, gitignored
    +-- logs/                  run logs, gitignored
    +-- metabase-data/         Metabase app DB, gitignored

## Setup

Prerequisites: Docker with Compose, direnv, a Spotify developer app (Web API), and a Premium account if your app is in development mode.

1. Create ~/.secrets/spotify (chmod 600, directory chmod 700):

    export SPOTIFY_CLIENT_ID="..."
    export SPOTIFY_CLIENT_SECRET="..."
    export SPOTIFY_REDIRECT_URI="http://127.0.0.1:8080"
    export SPOTIFY_TOKEN_CACHE="/path/to/.secrets/spotify_token_cache"

2. In the project root, .envrc contains one line, then run direnv allow:

    source ~/.secrets/spotify

3. Make sure the directory holding the token cache is mounted into the container (see docker-compose.yml) and writable by the container user.

4. Authorize once (manual OAuth: open the printed URL, then paste the redirect URL back into the terminal):

    docker compose run --rm spotify-collector python scripts/auth.py

5. Build and run the pipeline:

    docker compose build
    ./run_collection.sh

6. Install dbt packages and run the tests:

    docker compose run --rm spotify-collector dbt deps
    docker compose run --rm spotify-collector dbt test

DuckDB allows a single writer, so run_collection.sh stops the Metabase container before dbt runs and starts it again afterwards. Do the same when running dbt by hand.

## Metabase

IN PROGRESS

## Known Limitations

- Spotify only exposes the last 50 played tracks per call, so heavy listening between runs can be missed.
- Cron has no failure alerting yet; failures are only visible in logs/.
- Metabase is pinned to v0.59.4 for driver compatibility, and base images and most Python packages are not yet version-pinned.
- Raw JSON is the only non-rebuildable data and has no backup yet.

## Roadmap

- [x] Spotify OAuth and collection scripts
- [x] Scheduled collection (twice daily)
- [x] dbt staging and dimensional models
- [x] Metabase on NAS connected to DuckDB
- [ ] Fix duplicate keys in fct_listening_history
- [ ] Failure alerting for the cron job
- [ ] WIB time dimensions (hour, weekday/weekend)
- [ ] Dashboards
