# Docker & Laravel Sail Setup

This document defines the Docker and Laravel Sail setup standards for managing multiple
projects simultaneously in a development environment.

> For **native PHP** (non-Laravel) projects, see [docker_setup_php.md](./docker_setup_php.md).
> For simple single-service apps (e.g. the Python example in `src/example-site`), a plain
> `docker-compose.yml` is enough — see that project's compose file.

---

## Overview

We use **Laravel Sail** for Laravel applications (a Docker-based development environment) and
a plain Docker Compose setup for other stacks. Since multiple projects may run concurrently,
**proper port management is critical** to avoid conflicts.

**Key Philosophy:** Projects are stopped when not in use, freeing their ports for other
projects. Use dynamic port discovery to find available ports when starting projects.

---

## Multi-Project Port Management

### The Problem

When running multiple projects simultaneously, **port conflicts occur** because each project
tries to use the same default ports:

| Service | Default Port |
|---------|--------------|
| Web (Nginx/Apache) | 80 |
| MySQL | 3306 |
| Redis | 6379 |
| Mailpit | 8025, 1025 |

### The Solution

**Assign unique ports to each project dynamically** based on what's currently available.
Ports are freed when projects are stopped, allowing reuse.

### Port Ranges

| Service | Port Range |
|---------|------------|
| Web | 8000-8099 |
| MySQL | 33061-33099 |
| Redis | 6379-6399 |
| Mailpit (Web) | 8025-8099 |
| Mailpit (SMTP) | 1025-1099 |

---

## Port Discovery & Assignment

### Quick Port Check

```bash
# Check what's currently running
docker ps --format "table {{.Names}}\t{{.Ports}}"

# Check specific port ranges
lsof -i :8000-8010    # Web ports
lsof -i :33061-33070  # MySQL ports
```

### Port Discovery Script (`scripts/find-ports.sh`)

```bash
#!/bin/bash
# Find available ports for a new project

port_available() { ! lsof -i :$1 > /dev/null 2>&1; }

find_next_port() {
    local port=$1
    while [ $port -le $2 ]; do
        if port_available $port; then echo $port; return 0; fi
        ((port++))
    done
    echo "No available ports in range $1-$2" >&2
    return 1
}

APP_PORT=$(find_next_port 8000 8099)
DB_PORT=$(find_next_port 33061 33099)

echo "APP_PORT=$APP_PORT"
echo "FORWARD_DB_PORT=$DB_PORT"
echo "Add these to your .env file"
```

---

## Sail Configuration

### 1. Environment Variables (`.env`)

```bash
# Application
APP_PORT=8000
APP_URL=http://localhost:${APP_PORT}

# Database (MySQL)
FORWARD_DB_PORT=33061
DB_HOST=mysql
DB_PORT=3306          # Internal Docker port (don't change)
DB_DATABASE=taskflow
DB_USERNAME=sail
DB_PASSWORD=password

# Redis
FORWARD_REDIS_PORT=6379
REDIS_HOST=redis

# Mailpit
FORWARD_MAILPIT_PORT=8025
```

**Key Points:**
- `FORWARD_*` variables map host ports to container ports
- Internal container ports (3306, 6379, etc.) remain unchanged
- Only `FORWARD_*` ports need to be unique across projects

### 2. Container Naming Convention

Use the pattern `{project-name}-{service}` to avoid conflicts:

```yaml
services:
  laravel.test:
    container_name: taskflow-app
  mysql:
    container_name: taskflow-mysql
    ports:
      - '${FORWARD_DB_PORT:-3306}:3306'
  redis:
    container_name: taskflow-redis
    ports:
      - '${FORWARD_REDIS_PORT:-6379}:6379'
```

---

## Starting and Stopping Projects

### Starting

```bash
cd /path/to/project
./vendor/bin/sail up -d     # or: sail up -d (with alias)
sail ps                     # verify containers are running
```

### Stopping (frees ports for other projects)

```bash
sail down                   # stop containers
sail down -v                # stop AND remove volumes (deletes DB data!)
```

### Viewing Logs

```bash
sail logs            # all logs
sail logs -f         # follow
sail logs mysql      # service-specific
```

---

## Troubleshooting

### Port Already in Use
```
Error starting userland proxy: listen tcp 0.0.0.0:8000: bind: address already in use
```
```bash
lsof -i :8000                          # find what's using it
docker ps --filter "publish=8000"      # is it another project?
# Either stop the other project, or pick a new port in .env
```

### Container Name Already in Use
```bash
docker ps -a | grep taskflow-app   # check for a stopped container
docker rm taskflow-app             # remove it
docker container prune             # or remove all stopped containers
```

### Database Connection Failed (`SQLSTATE[HY000] [2002] Connection refused`)
```bash
sail ps                     # is MySQL running?
sail logs mysql
# Verify .env: DB_HOST=mysql (not 127.0.0.1), DB_PORT=3306 (internal port)
sail artisan config:clear
```

### Connecting from Host Tools (TablePlus, etc.)
Use the `FORWARD_DB_PORT` from your `.env`:
```
Host: 127.0.0.1
Port: 33061        # your FORWARD_DB_PORT
Username: sail
Password: password
Database: taskflow
```

---

## Best Practices

1. **Always stop projects when done** — frees ports and reduces resource usage.
2. **Document ports in the project README** — list every service port.
3. **Use port discovery before starting** — run `find-ports.sh`, then start.
4. **Helpful shell aliases:**
   ```bash
   alias sail='[ -f sail ] && sh sail || sh vendor/bin/sail'
   alias sa='sail artisan'
   alias sat='sail artisan test'
   alias sup='sail up -d'
   alias sdown='sail down'
   alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'
   ```

---

## Quick Reference

```bash
# Project management
sail up -d              # Start project
sail down               # Stop project (frees ports)
sail ps                 # View running containers

# Artisan
sail artisan migrate    # Run migrations
sail artisan test       # Run tests

# Package management
sail composer install   # Install PHP dependencies
sail npm run dev        # Run the Vite dev server

# Shell access
sail bash               # Enter app container
sail mysql              # Enter MySQL CLI
```

---

## Resources
- [Laravel Sail Documentation](https://laravel.com/docs/sail)
- [Docker Compose Reference](https://docs.docker.com/compose/)

---

**Version:** 1.0.0
**Last Updated:** 2026-06-01
