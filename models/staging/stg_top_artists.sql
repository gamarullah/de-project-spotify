{{ config(materialized='view') }}

WITH all_artists AS
(
SELECT
    a.collected_at
    ,'short_term' term
    ,UNNEST(a.data.short_term) artist
FROM read_json('/app/raw/top_artists/*.json') a
UNION ALL
SELECT
    a.collected_at
    ,'medium_term' term
    ,UNNEST(a.data.medium_term) artist
FROM read_json('/app/raw/top_artists/*.json') a
UNION ALL
SELECT
    a.collected_at
    ,'long_term' term
    ,UNNEST(a.data.long_term) artist
FROM read_json('/app/raw/top_artists/*.json') a
)

SELECT
    collected_at::TIMESTAMP collected_at
    ,term
    ,artist.rank::INT artist_rank
    ,artist.artist_id::VARCHAR artist_id
    ,artist.artist_name::VARCHAR artist_name
    ,array_to_string(artist.genres,', ')::VARCHAR genres
    ,artist.popularity::INT popularity
    ,artist.followers::INT followers

FROM all_artists