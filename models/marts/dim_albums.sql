{{ config(materialized='table') }}

SELECT
    collected_at
    ,album_id
    ,album_name
    ,album_release_date
    ,album_release_year
FROM stg_recently_played
QUALIFY ROW_NUMBER() OVER (PARTITION BY album_id ORDER BY collected_at DESC) = 1
ORDER BY album_id ASC