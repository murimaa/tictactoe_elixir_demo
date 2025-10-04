# Tictactoe Phoenix App Deployment Guide

This guide covers deploying your Phoenix Tictactoe application using Docker in various environments.

## Prerequisites

- Docker and Docker Compose installed
- Git (for version control)
- Basic understanding of environment variables

## Quick Start

1. **Setup Environment**
   ```bash
   ./app.sh setup-env
   ```

2. **Deploy Application**
   ```bash
   ./app.sh release
   ./app.sh prod-start
   ```

3. **Access Application**
   Open your browser to `http://localhost:4000`

## Environment Configuration

### Required Environment Variables

Copy `.env.example` to `.env` and configure:

```bash
cp .env.example .env
```

**Essential variables:**
- `SECRET_KEY_BASE` - Generate with `mix phx.gen.secret` (64 characters)
- `PHX_HOST` - Your domain name (e.g., `example.com`)
- `PORT` - Port to run on (default: 4000)

**Production variables:**
```env
PHX_SERVER=true
PHX_HOST=yourdomain.com
PORT=4000
MIX_ENV=prod
SECRET_KEY_BASE=your-very-long-secret-key-base-here
```

## Deployment Methods

### Method 1: Using the Unified App Script (Recommended)

The included `app.sh` script provides easy commands for all workflows:

```bash
# Development workflow
./app.sh dev-start          # Start development environment
./app.sh dev-logs           # View development logs
./app.sh dev-stop           # Stop development

# Quality checks
./app.sh quality-check      # Run all quality checks
./app.sh fix-format         # Fix code formatting

# Production workflow
./app.sh release            # Build and test release
./app.sh prod-start         # Start production container
./app.sh prod-logs          # View production logs
./app.sh health             # Health check
./app.sh prod-stop          # Stop production

# Utilities
./app.sh status             # Show system status
./app.sh cleanup            # Clean up resources
```

### Method 2: Manual Docker Commands

**Build the image:**
```bash
docker build -t tictactoe:latest .
```

**Run production container:**
```bash
docker run -d \
  --name tictactoe-web \
  --env-file .env \
  -p 4000:4000 \
  --restart unless-stopped \
  tictactoe:latest
```

**Run with docker-compose:**
```bash
# Production
docker-compose up -d web

# Development
docker-compose --profile dev up web-dev
```

## Cloud Platform Deployment

### Fly.io (Recommended for Phoenix apps)

1. **Install Fly CLI:**
   ```bash
   curl -L https://fly.io/install.sh | sh
   ```

2. **Initialize Fly app:**
   ```bash
   fly launch
   ```

3. **Set secrets:**
   ```bash
   fly secrets set SECRET_KEY_BASE=$(mix phx.gen.secret)
   fly secrets set PHX_HOST=yourapp.fly.dev
   ```

4. **Deploy:**
   ```bash
   fly deploy
   ```

### Railway

1. **Connect to Railway:**
   ```bash
   # Install Railway CLI
   npm install -g @railway/cli
   
   # Login and deploy
   railway login
   railway link
   railway up
   ```

2. **Set environment variables in Railway dashboard:**
   - `SECRET_KEY_BASE`
   - `PHX_HOST`
   - `PORT=4000`
   - `PHX_SERVER=true`

### DigitalOcean App Platform

1. **Create `app.yaml`:**
   ```yaml
   name: tictactoe
   services:
   - name: web
     source_dir: /
     dockerfile_path: Dockerfile
     http_port: 4000
     instance_count: 1
     instance_size_slug: basic-xxs
     envs:
     - key: SECRET_KEY_BASE
       value: your-secret-key-base
     - key: PHX_HOST
       value: your-app.ondigitalocean.app
     - key: PHX_SERVER
       value: "true"
   ```

2. **Deploy via CLI or web interface**

### Generic VPS Deployment

1. **Setup Docker on VPS:**
   ```bash
   # Ubuntu/Debian
   sudo apt update
   sudo apt install docker.io docker-compose
   sudo systemctl start docker
   sudo systemctl enable docker
   ```

2. **Clone and deploy:**
   ```bash
   git clone https://github.com/yourusername/tictactoe.git
   cd tictactoe
   ./app.sh setup-env
   # Edit .env with your settings
   ./app.sh release
   ./app.sh prod-start
   ```

3. **Setup reverse proxy (optional):**
   ```bash
   # nginx config example
   server {
       listen 80;
       server_name yourdomain.com;
       location / {
           proxy_pass http://localhost:4000;
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
       }
   }
   ```

## SSL/HTTPS Setup

### Using Nginx + Let's Encrypt

```bash
# Install certbot
sudo apt install certbot python3-certbot-nginx

# Get certificate
sudo certbot --nginx -d yourdomain.com

# Update nginx config
server {
    listen 443 ssl;
    server_name yourdomain.com;
    
    ssl_certificate /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;
    
    location / {
        proxy_pass http://localhost:4000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## Monitoring and Maintenance

### Health Checks

The application includes basic health monitoring:

```bash
# Check if app is responding
curl -f http://localhost:4000/

# Using the app script
./app.sh health
```

### Viewing Logs

```bash
# Production logs
./app.sh prod-logs

# Development logs
./app.sh dev-logs

# Docker logs directly
docker logs -f tictactoe-web
```

### Updates and Maintenance

```bash
# Pull latest changes
git pull origin main

# Rebuild and redeploy
./app.sh release
./app.sh prod-start

# Or step by step
./app.sh prod-stop
./app.sh build
./app.sh prod-start
```

## Troubleshooting

### Common Issues

1. **Port already in use:**
   ```bash
   # Find what's using the port
   sudo lsof -i :4000
   
   # Kill the process or use different port
   PORT=4001 ./app.sh prod-start
   ```

2. **Secret key base missing:**
   ```bash
   # Generate new secret
   SECRET_KEY_BASE=$(mix phx.gen.secret) ./app.sh prod-start
   ```

3. **Docker build fails:**
   ```bash
   # Clean Docker cache
   docker builder prune -a
   
   # Rebuild without cache
   docker build --no-cache -t tictactoe:latest .
   ```

4. **Container won't start:**
   ```bash
   # Check system status
   ./app.sh status
   
   # Check container logs
   ./app.sh prod-logs
   
   # Run interactively for debugging
   docker run -it --env-file .env tictactoe:latest /bin/bash
   ```

### Performance Optimization

1. **Multi-stage build** (already implemented in Dockerfile)
2. **Asset optimization** (handled by Phoenix assets pipeline)
3. **Container resource limits:**
   ```bash
   docker run -d \
     --name tictactoe-web \
     --memory="512m" \
     --cpus="1" \
     --env-file .env \
     -p 4000:4000 \
     tictactoe:latest
   ```

## Security Best Practices

1. **Use strong secrets:**
   ```bash
   # Generate strong secret key base
   mix phx.gen.secret 64
   ```

2. **Secure environment variables:**
   - Never commit `.env` to version control
   - Use platform-specific secret management
   - Rotate secrets regularly

3. **Container security:**
   - Run as non-root user (already implemented)
   - Use specific base image tags
   - Regularly update base images

4. **Network security:**
   - Use HTTPS in production
   - Configure proper firewall rules
   - Use reverse proxy for additional security

## Database Integration (Future)

When you add a database to your application:

1. **Update docker-compose.yml:**
   ```yaml
   services:
     db:
       image: postgres:15
       environment:
         POSTGRES_PASSWORD: yourpassword
         POSTGRES_DB: tictactoe_prod
       volumes:
         - postgres_data:/var/lib/postgresql/data
   ```

2. **Update .env:**
   ```env
   DATABASE_URL=postgres://postgres:yourpassword@db:5432/tictactoe_prod
   ```

## Support

- Check the Phoenix documentation: https://hexdocs.pm/phoenix/
- Docker documentation: https://docs.docker.com/
- Open an issue in the repository for bugs or questions

## Changelog

- **v1.0** - Initial Docker setup with multi-stage build
- **v1.1** - Added deployment script and comprehensive guides
- **v1.2** - Added cloud platform deployment instructions
- **v2.0** - Unified app.sh script replacing deploy.sh and build.sh