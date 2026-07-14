import sys
import os
from datetime import datetime
from pathlib import Path

sys.path.append(str(Path(__file__).parent))

# Modules
from auth import get_spotify_client
from utils import get_raw_path, save_json, file_exists_for_today


def collect_recently_played(sp):
    """Collect recently played tracks — up to 50 most recent"""
    print("\n Collecting recently played tracks...")
    
    results = sp.current_user_recently_played(limit=50)
    
    tracks = []
    for item in results['items']:
        track = item['track']
        tracks.append({
            'played_at': item['played_at'],
            'track_id': track['id'],
            'track_name': track['name'],
            'track_duration_ms': track['duration_ms'],
            'artist_id': track['artists'][0]['id'],
            'artist_name': track['artists'][0]['name'],
            'album_id': track['album']['id'],
            'album_name': track['album']['name'],
            'album_release_date': track['album']['release_date'],
            'popularity': track['popularity'],
            'explicit': track['explicit'],
            'context_type': item.get('context', {}).get('type')
                           if item.get('context') else None,
        })
    
    print(f"Collected {len(tracks)} recently played tracks")
    return tracks


def collect_top_tracks(sp):
    """Collect top tracks across three time ranges"""
    print("\n Collecting top tracks...")
    
    time_ranges = {
        'short_term': '4 weeks',
        'medium_term': '6 months',
        'long_term': 'all time'
    }
    
    top_tracks = {}
    
    for time_range, label in time_ranges.items():
        results = sp.current_user_top_tracks(
            limit=50,
            time_range=time_range
        )
        
        tracks = []
        for idx, track in enumerate(results['items']):
            tracks.append({
                'rank': idx + 1,
                'track_id': track['id'],
                'track_name': track['name'],
                'artist_id': track['artists'][0]['id'],
                'artist_name': track['artists'][0]['name'],
                'album_name': track['album']['name'],
                'popularity': track['popularity'],
                'explicit': track['explicit'],
                'duration_ms': track['duration_ms'],
            })
        
        top_tracks[time_range] = tracks
        print(f" Collected {len(tracks)} top tracks ({label})")
    
    return top_tracks


def collect_top_artists(sp):
    """Collect top artists across three time ranges"""
    print("\n Collecting top artists...")
    
    time_ranges = {
        'short_term': '4 weeks',
        'medium_term': '6 months',
        'long_term': 'all time'
    }
    
    top_artists = {}
    
    for time_range, label in time_ranges.items():
        results = sp.current_user_top_artists(
            limit=50,
            time_range=time_range
        )
        
        artists = []
        for idx, artist in enumerate(results['items']):
            artists.append({
                'rank': idx + 1,
                'artist_id': artist['id'],
                'artist_name': artist['name'],
                'genres': artist['genres'],
                'popularity': artist['popularity'],
                'followers': artist['followers']['total'],
            })
        
        top_artists[time_range] = artists
        print(f"✓ Collected {len(artists)} top artists ({label})")
    
    return top_artists


def collect_audio_features(sp, recently_played: list):
    """
    Collect audio features for recently played tracks.
    NOTE: Spotify restricted this endpoint for new apps after November 2024.
    """
    print("\n Collecting audio features...")
    
    track_ids = list(set([
        track['track_id']
        for track in recently_played
        if track['track_id']
    ]))
    
    if not track_ids:
        print("✗ No track IDs found")
        return []
    
    audio_features = []
    batch_size = 100
    
    for i in range(0, len(track_ids), batch_size):
        batch = track_ids[i:i + batch_size]
        
        try:
            results = sp.audio_features(batch)
            for feature in results:
                if feature:
                    audio_features.append({
                        'track_id': feature['id'],
                        'danceability': feature['danceability'],
                        'energy': feature['energy'],
                        'key': feature['key'],
                        'loudness': feature['loudness'],
                        'mode': feature['mode'],
                        'speechiness': feature['speechiness'],
                        'acousticness': feature['acousticness'],
                        'instrumentalness': feature['instrumentalness'],
                        'liveness': feature['liveness'],
                        'valence': feature['valence'],
                        'tempo': feature['tempo'],
                        'duration_ms': feature['duration_ms'],
                        'time_signature': feature['time_signature'],
                    })
        except Exception as e:
            if '403' in str(e):
                print("⚠ Audio features endpoint restricted for this app")
                print("  Spotify deprecated this endpoint for new apps")
                print("  Skipping audio features collection")
                return []
            else:
                print(f"✗ Unexpected error: {e}")
                return []
    
    print(f"✓ Collected audio features for {len(audio_features)} tracks")
    return audio_features


def run_collection():
    """Main collection function — runs all collectors"""
    
    date_str = datetime.now().strftime('%Y-%m-%d')
    print(f"\n{'='*50}")
    print(f"Spotify Data Collection — {date_str}")
    print(f"{'='*50}")
    
    print("\n Authenticating with Spotify...")
    sp = get_spotify_client()
    user = sp.current_user()
    print(f"Logged in as: {user['display_name']}")
    
    recently_played = collect_recently_played(sp)
    save_json(
        recently_played,
        get_raw_path('recently_played', date_str)
    )
    
    top_tracks = collect_top_tracks(sp)
    save_json(
        top_tracks,
        get_raw_path('top_tracks', date_str)
    )
    
    top_artists = collect_top_artists(sp)
    save_json(
        top_artists,
        get_raw_path('top_artists', date_str)
    )
    
    # Audio features — may be restricted for new apps
    audio_features = collect_audio_features(sp, recently_played)
    if audio_features:
        save_json(
            audio_features,
            get_raw_path('audio_features', date_str)
        )
    else:
        print("⚠ Audio features not saved (endpoint restricted)")
    
    print(f"\n{'='*50}")
    print(f"Collection complete!")
    print(f"{'='*50}\n")


if __name__ == "__main__":
    run_collection()
