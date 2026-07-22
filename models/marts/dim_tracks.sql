{{ config(materialized='table') }}

WITH
tracks AS
(
SELECT
    collected_at
    ,artist_id
    ,album_id
    ,album_name
    ,track_id
    ,track_name
    ,track_duration_ms
    ,explicit
    ,popularity
FROM stg_recently_played

UNION ALL

SELECT
    collected_at
    ,artist_id
    ,NULL AS album_id
    ,album_name
    ,track_id
    ,track_name
    ,duration_ms track_duration_ms
    ,explicit
    ,popularity
FROM stg_top_tracks
)

SELECT *
FROM tracks
QUALIFY ROW_NUMBER() OVER (PARTITION BY track_id ORDER BY album_id NULLS LAST, collected_at DESC) = 1
ORDER BY artist_id ASC, album_name ASC, track_id 