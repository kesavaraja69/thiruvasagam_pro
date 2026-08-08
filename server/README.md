# Thiruvasagam Songs Server

A lightweight Docker-based server to host and stream audio songs.

## Features

- 🎵 Audio streaming with range request support (for seeking)
- 📁 Auto-indexing of songs directory
- 🔄 CORS enabled for cross-origin requests
- ❤️ Health check endpoint
- 📋 JSON API endpoint for listing songs

## Quick Start

### Using Docker Compose (Recommended)

```bash
cd server
docker-compose up -d
```

### Using Docker

```bash
cd server
docker build -t thiruvasagam-songs .
docker run -d -p 8080:80 --name thiruvasagam-songs thiruvasagam-songs
```

## Adding New Songs

1. Simply place your `.mp3`, `.wav`, `.ogg`, `.m4a`, or `.flac` files in the `songs/` directory
2. If using Docker Compose with the volume mount, songs are available immediately
3. If using plain Docker, rebuild the image:
   ```bash
   docker build -t thiruvasagam-songs .
   docker stop thiruvasagam-songs
   docker rm thiruvasagam-songs
   docker run -d -p 8080:80 --name thiruvasagam-songs thiruvasagam-songs
   ```

## API Endpoints

| Endpoint | Description |
|----------|-------------|
| `GET /` | Browse all songs (autoindex) |
| `GET /health` | Health check (returns JSON status) |
| `GET /api/songs` | List songs in JSON format |
| `GET /songs/song1.mp3` | Direct access to a song file |

## URL Examples

Once running on port 8080:

- **Browse songs:** http://localhost:8080/
- **Health check:** http://localhost:8080/health
- **List songs (JSON):** http://localhost:8080/api/songs
- **Play a song:** http://localhost:8080/song1.mp3

## Configuration

- Default port: `8080` (mapped from container port `80`)
- Songs directory: `./songs/`
- Config file: `nginx.conf`

## Stopping the Server

```bash
docker-compose down
```
