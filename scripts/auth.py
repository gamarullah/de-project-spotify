import spotipy
from spotipy.oauth2 import SpotifyOAuth
import os

def get_spotify_client():
    """
    Creates and returns an authenticated Spotify client.
    First run: opens browser for OAuth authorization.
    Subsequent runs: uses cached token automatically.
    """
    scopes = [
        "user-read-recently-played",
        "user-top-read",
        "user-library-read",
    ]
    
    auth_manager = SpotifyOAuth(
        client_id=os.environ.get("SPOTIFY_CLIENT_ID"),
        client_secret=os.environ.get("SPOTIFY_CLIENT_SECRET"),
        redirect_uri=os.environ.get("SPOTIFY_REDIRECT_URI"),
        scope=" ".join(scopes),
        cache_path=os.path.expanduser(
            "~/.secrets/spotify_token_cache"
        ),
        open_browser=False
    )
    
    return spotipy.Spotify(auth_manager=auth_manager)


def test_connection():
    """Authentication testing"""
    try:
        sp = get_spotify_client()
        user = sp.current_user()
        print(f"Connected as: {user['display_name']}")
        print(f"Spotify ID: {user['id']}")
        return True
    except Exception as e:
        print(f"Connection failed: {e}")
        return False


if __name__ == "__main__":
    test_connection()
