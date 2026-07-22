{{
    config(
        materialized='incremental'
        ,unique_key=['played_at','track_id','context_type']
        )
}}

SELECT
    collected_at
    ,played_at
    ,track_id
    ,context_type
FROM stg_recently_played

{% if is_incremental() %}
WHERE played_at > (SELECT MAX(played_at) from {{this}})
{% endif %}