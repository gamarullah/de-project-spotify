{{ config(materialized='view') }}

WITH all_tracks AS
(
SELECT
    a.collected_at
    ,'short_term' term
    ,UNNEST(a.data.short_term) track
FROM read_json('/app/raw/top_tracks/*.json') a
UNION ALL
SELECT
    a.collected_at
    ,'medium_term' term
    ,UNNEST(a.data.medium_term) track
FROM read_json('/app/raw/top_tracks/*.json') a
UNION ALL
SELECT
    a.collected_at
    ,'long_term' term
    ,UNNEST(a.data.long_term) track
FROM read_json('/app/raw/top_tracks/*.json') a
)

SELECT
    collected_at::TIMESTAMP collected_at
    ,term
    ,track.rank::INT track_rank
    ,track.track_id::VARCHAR track_id
    ,track.track_name::VARCHAR track_name
    ,track.artist_id::VARCHAR artist_id
    ,track.artist_name::VARCHAR artist_name
    ,track.album_name::VARCHAR album_name
    ,track.popularity::INT popularity
    ,track.explicit::BOOLEAN explicit
    ,track.duration_ms::INTEGER duration_ms

FROM all_tracks