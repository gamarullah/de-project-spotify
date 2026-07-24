{{ config(materialized='table') }}

SELECT
    * EXCLUDE(duration_ms, collected_at)
FROM {{ ref('stg_audio_features') }}
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY track_id
    ORDER BY collected_at DESC
) = 1