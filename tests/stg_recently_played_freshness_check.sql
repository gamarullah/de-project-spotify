WITH
latest AS
(
SELECT MAX(collected_at) last_collected
FROM {{ ref('stg_recently_played') }}
)

SELECT *
FROM latest
WHERE last_collected < CURRENT_TIMESTAMP - INTERVAL '12 hours'