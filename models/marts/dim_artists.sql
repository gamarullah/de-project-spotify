{{ config(materialized='table') }}

WITH
artists AS
(
SELECT 
    collected_at
    ,artist_id
    ,artist_name
    ,genres
FROM stg_top_artists

UNION ALL

SELECT 
    collected_at
    ,artist_id
    ,artist_name
    ,NULL AS genres
FROM stg_top_tracks

UNION ALL

SELECT 
    collected_at
    ,artist_id
    ,artist_name
    ,NULL AS genres
FROM stg_recently_played
)

SELECT *
FROM artists
QUALIFY ROW_NUMBER() OVER (PARTITION BY artist_id ORDER BY genres NULLS LAST, collected_at DESC) = 1
ORDER BY artist_id ASC