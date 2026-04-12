# FoodSense Server Setup

Production deployment guide for the FoodSense Node.js server on DigitalOcean (or any VPS) with Docker, HTTPS, and security hardening.

---

## Table of Contents

- [Overview](#overview)
- [Docker Compose Setup](#docker-compose-setup)
- [Environment Variables](#environment-variables)
- [Firebase Admin SDK Setup](#firebase-admin-sdk-setup)
- [Database Migrations](#database-migrations)
- [HTTPS with Nginx and Let's Encrypt](#https-with-nginx-and-lets-encrypt)
- [Security Hardening](#security-hardening)
- [Monitoring and Maintenance](#monitoring-and-maintenance)

---

## Overview

The server stack:

```
  Internet
     |
     v
  Nginx (HTTPS termination, port 443)
     |
     v
  Docker Compose
     |
     +---> app (Node.js 20 Alpine, port 3000)
     |       +---> Express + Prisma
     |       +---> Firebase Admin SDK
     |       +---> Gemini API calls
     |
     +---> postgres (PostgreSQL 15 Alpine)
     |       +---> 18 tables (Prisma schema)
     |       +---> Internal network only
     |
     +---> redis (Redis 7 Alpine)
             +---> Rate limiting
             +---> Session caching
             +---> Internal network only
```

PostgreSQL and Redis are not exposed to the public internet -- they communicate with the app container over Docker's internal network only.

---

## Docker Compose Setup

### 1. Prepare the server

```bash
# On a fresh Ubuntu/Debian VPS
sudo apt update && sudo apt upgrade -y
sudo apt install -y docker.io docker-compose-v2 nginx certbot python3-certbot-nginx

# Start Docker
sudo systemctl enable docker
sudo systemctl start docker

# Add your user to the docker group (log out and back in after)
sudo usermod -aG docker $USER
```

### 2. Clone the repository

```bash
git clone https://github.com/nitinyadav26/FoodDetectionApp.git
cd FoodDetectionApp/server
```

### 3. Configure environment

```bash
cp .env.example .env
nano .env
```

See [Environment Variables](#environment-variables) below for all required values.

### 4. Place Firebase credentials

Copy your Firebase service account JSON file:

```bash
scp firebase-service-account.json your-server:~/FoodDetectionApp/server/
```

### 5. Start the stack

```bash
docker compose up -d
```

This starts three containers:
- `server-postgres-1` -- PostgreSQL 15
- `server-redis-1` -- Redis 7
- `server-app-1` -- Node.js app on port 3000

### 6. Run migrations and seed

```bash
# Create all 18 database tables
docker compose exec app npx prisma migrate deploy

# Seed initial data (badges, leagues)
docker compose exec app npx prisma db seed
```

### 7. Verify

```bash
curl http://localhost:3000/health
# Should return: {"status":"ok"}
```

---

## Environment Variables

Create `server/.env` with these values:

```env
# Database
DATABASE_URL=postgresql://postgres:YOUR_STRONG_DB_PASSWORD@postgres:5432/foodsense
POSTGRES_PASSWORD=YOUR_STRONG_DB_PASSWORD

# Redis
REDIS_URL=redis://:YOUR_STRONG_REDIS_PASSWORD@redis:6379
REDIS_PASSWORD=YOUR_STRONG_REDIS_PASSWORD

# Gemini AI
GEMINI_API_KEY=your-gemini-api-key

# Firebase
FIREBASE_SERVICE_ACCOUNT_PATH=./firebase-service-account.json

# JWT
JWT_SECRET=your-random-secret-at-least-32-characters-long

# Server
PORT=3000
NODE_ENV=production
```

### Generating strong passwords

```bash
# Generate a random 32-character password
openssl rand -base64 32
```

### Variable reference

| Variable | Required | Description |
|---|---|---|
| `DATABASE_URL` | Yes | PostgreSQL connection string. Host is `postgres` (Docker service name) |
| `POSTGRES_PASSWORD` | Yes | Password for the PostgreSQL superuser. Must match the password in `DATABASE_URL` |
| `REDIS_URL` | Yes | Redis connection string with password. Host is `redis` (Docker service name) |
| `REDIS_PASSWORD` | Yes | Redis authentication password. Must match the password in `REDIS_URL` |
| `GEMINI_API_KEY` | Yes | Google Gemini API key for server-side AI features (coach, quiz, insights) |
| `FIREBASE_SERVICE_ACCOUNT_PATH` | Yes | Path to Firebase service account JSON (mounted as Docker volume) |
| `JWT_SECRET` | Yes | Secret for signing JWTs. Use at least 32 random characters |
| `PORT` | No | Server port (default: 3000) |
| `NODE_ENV` | No | `production` or `development` (default: development) |

---

## Firebase Admin SDK Setup

The server uses Firebase Admin SDK to verify authentication tokens from mobile clients.

### 1. Get the service account key

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to **Project Settings** (gear icon) > **Service Accounts**
4. Click **Generate New Private Key**
5. Save the JSON file as `firebase-service-account.json`

### 2. Place the file

The `docker-compose.yml` mounts this file as a read-only volume:

```yaml
volumes:
  - ./firebase-service-account.json:/app/firebase-service-account.json:ro
```

Place the file in the `server/` directory alongside `docker-compose.yml`.

### 3. How auth works

```
  Mobile App
     |
     v
  Firebase Auth (sign in with Google/email/etc.)
     |
     v
  Firebase ID Token
     |
     v
  POST /auth/verify { token: "..." }
     |
     v
  Server: verifyIdToken(token)
     |
     v
  Create or find User + Profile in PostgreSQL
     |
     v
  Return user data (JWT for subsequent requests)
```

The server verifies the Firebase token, looks up or creates the user in PostgreSQL, and returns the user record. Subsequent API calls use the Firebase UID from the verified token.

---

## Database Migrations

### Running migrations

```bash
# Production (inside Docker)
docker compose exec app npx prisma migrate deploy

# Development (local)
cd server
npx prisma migrate dev
```

### Creating new migrations

When you change `prisma/schema.prisma`:

```bash
# Generate migration SQL (development only)
npx prisma migrate dev --name describe_your_change

# This creates a new migration file in prisma/migrations/
```

### Resetting the database (development only)

```bash
npx prisma migrate reset
# WARNING: This drops all data and recreates all tables
```

### Seeding

```bash
docker compose exec app npx prisma db seed
```

The seed script creates initial badges (50 across 6 categories) and league tiers.

### Schema overview

The database has 18 tables. See [ARCHITECTURE.md](ARCHITECTURE.md) for the full entity relationship diagram.

---

## HTTPS with Nginx and Let's Encrypt

### 1. Configure DNS

Point your domain (e.g., `api.foodsense.app`) to your server's IP address via an A record.

### 2. Create Nginx config

```bash
sudo nano /etc/nginx/sites-available/foodsense
```

```nginx
server {
    listen 80;
    server_name api.foodsense.app;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;

        # Increase timeouts for AI endpoints (meal plan, insights)
        proxy_read_timeout 120s;
        proxy_connect_timeout 30s;
    }

    # Increase max body size for image uploads
    client_max_body_size 10M;
}
```

### 3. Enable the site

```bash
sudo ln -s /etc/nginx/sites-available/foodsense /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### 4. Obtain SSL certificate

```bash
sudo certbot --nginx -d api.foodsense.app
```

Certbot will:
- Obtain a free Let's Encrypt certificate
- Modify the Nginx config to add SSL
- Set up automatic renewal

### 5. Verify HTTPS

```bash
curl https://api.foodsense.app/health
```

### 6. Auto-renewal

Certbot installs a systemd timer for automatic renewal. Verify it:

```bash
sudo certbot renew --dry-run
```

---

## Security Hardening

### Close public database/Redis ports

The `docker-compose.yml` is already configured to NOT expose PostgreSQL or Redis ports publicly. Only the app container (port 3000) is accessible. Verify:

```yaml
services:
  postgres:
    # No "ports:" section -- internal only
  redis:
    # No "ports:" section -- internal only
  app:
    ports:
      - "3000:3000"    # Only the app is exposed
```

### Firewall (UFW)

```bash
# Allow only SSH, HTTP, HTTPS
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
sudo ufw enable
```

### Password rotation

Rotate passwords periodically:

1. Generate new passwords:
   ```bash
   openssl rand -base64 32
   ```

2. Update `.env` with new `POSTGRES_PASSWORD`, `REDIS_PASSWORD`, `JWT_SECRET`

3. Update `DATABASE_URL` and `REDIS_URL` to match

4. Restart the stack:
   ```bash
   docker compose down
   docker compose up -d
   ```

5. For PostgreSQL password changes, you may need to update the password inside the container:
   ```bash
   docker compose exec postgres psql -U postgres -c "ALTER USER postgres PASSWORD 'new_password';"
   ```

### Rate limiting

The server uses Redis-backed rate limiting via `rate-limiter-flexible`. Default limits are enforced in `src/middleware/`. To adjust:

- Edit the rate limit middleware in `server/src/middleware/`
- Restart the app container: `docker compose restart app`

### Environment file permissions

```bash
chmod 600 server/.env
chmod 600 server/firebase-service-account.json
```

### Docker security

```bash
# Keep Docker updated
sudo apt update && sudo apt upgrade docker.io -y

# Prune unused images/containers periodically
docker system prune -af --volumes
```

### Secrets checklist

Before deploying, verify:

- [ ] `.env` is in `.gitignore` (never committed)
- [ ] `firebase-service-account.json` is in `.gitignore`
- [ ] No API keys in source code
- [ ] `JWT_SECRET` is at least 32 random characters
- [ ] Database and Redis passwords are strong (32+ characters)
- [ ] `NODE_ENV=production` is set

---

## Monitoring and Maintenance

### View logs

```bash
# All containers
docker compose logs -f

# Just the app
docker compose logs -f app

# Just PostgreSQL
docker compose logs -f postgres
```

### Health check

```bash
curl http://localhost:3000/health
```

### Database backup

```bash
# Backup
docker compose exec postgres pg_dump -U postgres foodsense > backup_$(date +%Y%m%d).sql

# Restore
cat backup_20260412.sql | docker compose exec -T postgres psql -U postgres foodsense
```

### Restart services

```bash
# Restart everything
docker compose restart

# Restart just the app (after code changes)
docker compose restart app

# Full rebuild (after Dockerfile changes)
docker compose up -d --build
```

### Update the app

```bash
cd FoodDetectionApp/server
git pull origin main
docker compose up -d --build
docker compose exec app npx prisma migrate deploy
```

### Disk space

Monitor disk usage, especially for PostgreSQL data:

```bash
# Check Docker volumes
docker system df

# Check total disk
df -h
```

### Performance

For high-traffic deployments, consider:

- Increasing the DigitalOcean droplet size (4+ GB RAM recommended)
- Adding connection pooling for PostgreSQL (PgBouncer)
- Enabling Redis persistence for rate limit state survival across restarts
- Adding a CDN for static assets if serving images
