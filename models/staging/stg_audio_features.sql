{{ config(materialized='view') }}

WITH base AS
(
SELECT 
    r.collected_at
    ,UNNEST(r.data) audio
FROM read_json('/app/raw/audio_features/*.json') r
)

SELECT 
    collected_at::TIMESTAMP collected_at
    ,audio.track_id::VARCHAR track_id
    ,audio.danceability::FLOAT danceability
    ,audio.energy::FLOAT energy
    ,audio.key::INTEGER musical_key
    ,audio.loudness::FLOAT loudness
    ,audio.mode::INTEGER musical_mode
    ,audio.speechiness::FLOAT speechiness
    ,audio.acousticness::FLOAT acousticness
    ,audio.instrumentalness::FLOAT instrumentalness
    ,audio.liveness::FLOAT liveness
    ,audio.valence::FLOAT valence
    ,audio.tempo::FLOAT tempo
    ,audio.duration_ms::INTEGER duration_ms
    ,audio.time_signature::INTEGER time_signature

FROM base