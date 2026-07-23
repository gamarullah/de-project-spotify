{{ config(materialized='view') }}

WITH base AS
(
SELECT 
    r.collected_at
    ,UNNEST(r.data) track
FROM read_json('/app/raw/recently_played/*.json') r
)

SELECT 
    collected_at::TIMESTAMP collected_at
    ,track.played_at::TIMESTAMP played_at
    ,track.track_id::VARCHAR track_id
    ,track.track_name::VARCHAR track_name
    ,track.track_duration_ms::INTEGER track_duration_ms
    ,track.artist_id::VARCHAR artist_id
    ,track.artist_name::VARCHAR artist_name
    ,track.album_id::VARCHAR album_id
    ,track.album_name::VARCHAR album_name
    ,TRY_CAST(track.album_release_date AS DATE) AS album_release_date
    ,TRY_CAST(LEFT(track.album_release_date, 4) AS INTEGER) AS album_release_year        
    ,track.popularity::INT popularity
    ,track.explicit::BOOLEAN explicit
    ,track.context_type::VARCHAR context_type

FROM base