# Docker Setup for Native PHP Applications

This document defines the Docker setup standards for **native PHP applications** (non-Laravel).
For Laravel applications using Sail, see [docker_setup.md](./docker_setup.md).

---

## Overview

Native PHP applications use **Docker Compose** with a custom Dockerfile instead of Laravel Sail.
A typical stack provides:

- **PHP 8.3+** with Apache (mod_rewrite enabled)
- **MySQL 8.0** for database storage
- **Mailpit** for email testing during development

**Key Differences from Laravel Sail:**

| Aspect | Laravel Sail | Native PHP (this doc) |
|--------|--------------|----------------------|
| PHP runtime | Sail-managed container | Custom `php:8.3-apache` Dockerfile |
| Command prefix | `./vendor/bin/sail` | `docker compose exec app` |
| Web server | Sail's built-in Nginx | Apache with `.htaccess` / mod_rewrite |
| Config format | `.env` | PHP array config file (`config.php`) |
| Email | Mailpit via Sail config | Mailpit via msmtp sendmail relay |

---

## Multi-Project Port Management

Port management follows the same strategy as `docker_setup.md`. See that document for the
full port discovery workflow and helper scripts.

| Service | Port Range | Default |
|---------|------------|---------|
| Web (Apache) | 8000-8099 | Project-specific |
| MySQL | 33061-33099 | 33061 |
| Mailpit (Web UI) | 8025-8099 | 8026+ |
| Mailpit (SMTP) | 1025-1099 | 1026+ |

**All ports are configurable via `.env`.**

---

## Service Stack

```
┌──────────────────────────────────────────────────┐
│                  Host Machine                     │
│                                                   │
│  ┌─────────────┐  ┌─────────┐  ┌──────────────┐  │
│  │  {p}-app    │  │{p}-mysql│  │ {p}-mailpit  │  │
│  │ PHP 8.3 +   │──│MySQL 8.0│  │ SMTP :1025   │  │
│  │ Apache      │  │ :3306   │  │ UI   :8025   │  │
│  │ :80→${PORT} │  │ →${PORT}│  │              │  │
│  └─────────────┘  └─────────┘  └──────────────┘  │
│                                                   │
│  Network: {project}-network (bridge)              │
└──────────────────────────────────────────────────┘
```

**app** — PHP 8.3 + Apache container with required extensions and msmtp for email relay.
Source code is bind-mounted for live editing.

**mysql** — MySQL 8.0 with the application database. Data persisted in a named volume.

**mailpit** — Catches all outgoing email from the app. The app's `sendmail` is replaced by
`msmtp`, which relays to Mailpit's SMTP port. A web UI displays captured emails.

> **Optional services.** Some projects add extra containers (for example an antivirus
> scanner, Redis, or a queue worker). Add them only when the application needs them, and
> document the connection details in the project README.

---

## Docker Compose Template

```yaml
services:
  app:
    build:
      context: .
      dockerfile: docker/Dockerfile
    container_name: {project}-app
    ports:
      - "${APP_PORT:-8080}:80"
    volumes:
      - ./public:/var/www/html/public
      - ./src:/var/www/html/src
      - ./docker/config.php:/var/www/html/config/config.php
    environment:
      - APP_PORT=${APP_PORT:-8080}
      - DB_HOST=mysql
      - DB_DATABASE=${DB_DATABASE:-taskflow}
      - DB_USERNAME=${DB_USERNAME:-taskflow}
      - DB_PASSWORD=${DB_PASSWORD:-secret}
    depends_on:
      mysql:
        condition: service_healthy
      mailpit:
        condition: service_started
    networks:
      - {project}-network
    restart: unless-stopped

  mysql:
    image: mysql:8.0
    container_name: {project}-mysql
    ports:
      - "${FORWARD_DB_PORT:-33061}:3306"
    environment:
      MYSQL_ROOT_PASSWORD: ${DB_ROOT_PASSWORD:-rootsecret}
      MYSQL_DATABASE: ${DB_DATABASE:-taskflow}
      MYSQL_USER: ${DB_USERNAME:-taskflow}
      MYSQL_PASSWORD: ${DB_PASSWORD:-secret}
    volumes:
      - {project}-mysql-data:/var/lib/mysql
      - ./docker/mysql/init.sql:/docker-entrypoint-initdb.d/01-init.sql
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-u", "root", "-p${DB_ROOT_PASSWORD:-rootsecret}"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 30s
    networks:
      - {project}-network
    restart: unless-stopped

  mailpit:
    image: axllent/mailpit
    container_name: {project}-mailpit
    ports:
      - "${FORWARD_MAILPIT_PORT:-8026}:8025"
      - "${FORWARD_MAILPIT_SMTP_PORT:-1026}:1025"
    networks:
      - {project}-network
    restart: unless-stopped

volumes:
  {project}-mysql-data:

networks:
  {project}-network:
    driver: bridge
```

Replace `{project}` with your project's short name.

---

## Dockerfile Template

```dockerfile
FROM php:8.3-apache

# System dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libzip-dev \
    libpng-dev \
    libicu-dev \
    libonig-dev \
    libcurl4-openssl-dev \
    msmtp \
    msmtp-mta \
    unzip \
    git \
    && rm -rf /var/lib/apt/lists/*

# PHP extensions
RUN docker-php-ext-install -j$(nproc) \
        mysqli \
        pdo_mysql \
        mbstring \
        curl \
        gd \
        zip \
        intl \
        opcache \
        fileinfo

# Apache modules
RUN a2enmod rewrite headers

# PHP config
RUN cp "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"

# Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html
EXPOSE 80
```

### Key PHP Extensions

| Extension | Purpose |
|-----------|---------|
| `mysqli`, `pdo_mysql` | Database access |
| `mbstring` | UTF-8 string handling |
| `gd` | Image processing |
| `zip` | File compression |
| `intl` | Internationalization |
| `opcache` | PHP bytecode caching |
| `fileinfo` | MIME type detection for uploads |
| `curl` | HTTP requests |

---

## Environment Configuration

### `.env` File

```bash
APP_PORT=8080
FORWARD_DB_PORT=33061
DB_DATABASE=taskflow
DB_USERNAME=taskflow
DB_PASSWORD=secret
DB_ROOT_PASSWORD=rootsecret
FORWARD_MAILPIT_PORT=8026
FORWARD_MAILPIT_SMTP_PORT=1026
```

### PHP Config File (`config.php`)

Native PHP applications use a PHP array config file that reads from environment variables.
This file is bind-mounted into the container — it is **not committed** with real credentials.

```php
<?php

declare(strict_types=1);

return [
    'app_url'  => 'http://localhost:' . ($_ENV['APP_PORT'] ?? '8080'),
    'database' => [
        'host'     => $_ENV['DB_HOST'] ?? 'mysql',
        'name'     => $_ENV['DB_DATABASE'] ?? 'taskflow',
        'username' => $_ENV['DB_USERNAME'] ?? 'taskflow',
        'password' => $_ENV['DB_PASSWORD'] ?? 'secret',
    ],
];
```

### Email Configuration (msmtp)

Replace sendmail with msmtp to relay outgoing mail to Mailpit.

**`docker/msmtp.conf`:**
```
defaults
auth           off
tls            off
logfile        /var/www/html/storage/logs/msmtp.log

account default
host           mailpit
port           1025
from           noreply@{project}.local
```

This is copied into the container at `/etc/msmtprc`. The `msmtp-mta` package symlinks it so
that PHP's `SENDMAIL_PATH` works unchanged.

---

## Starting and Stopping

### First-Time Setup

```bash
cd src/{project}
cp .env.example .env
docker ps --format "table {{.Names}}\t{{.Ports}}"   # check for port conflicts
docker compose up -d --build
docker compose ps                                    # wait for mysql "healthy"
docker compose exec app composer install
curl http://localhost:${APP_PORT}
```

### Daily Usage

```bash
docker compose up -d              # start
docker compose down               # stop (frees ports)
docker compose logs -f app        # follow app logs
docker compose exec app bash      # shell into the app container
```

---

## Troubleshooting

### Apache: 403 Forbidden or mod_rewrite not working
```bash
docker compose exec app apache2ctl -M | grep rewrite   # verify mod_rewrite
docker compose exec app cat /etc/apache2/sites-available/000-default.conf  # AllowOverride All
```

### MySQL: Connection refused
```bash
docker compose ps mysql        # is it healthy?
docker compose logs mysql
# Verify config uses 'mysql' as host (not localhost/127.0.0.1)
```

### Email: not appearing in Mailpit
```bash
docker compose exec app cat /etc/msmtprc
docker compose exec app bash -c 'echo "Test" | msmtp test@example.com'
curl http://localhost:${FORWARD_MAILPIT_PORT}
```

### Reset everything (nuclear option)
```bash
docker compose down -v    # stops containers AND deletes all volumes (data loss!)
docker compose up -d --build
```

---

**Version:** 1.0.0
**Last Updated:** 2026-06-01
