# Containers and ports

Reference material. `AGENTS.md` and the repo's own `CLAUDE.md` are authoritative; this file
explains the container conventions shared by every repo and holds the **port registry**, which
is the part you actually need.

Keep it short. A long Laravel Sail tutorial that assumes a `sail` alias the agent does not
have, tells the reader to discover ports dynamically, and presents `sail down -v`,
`docker system prune -a` and `docker stop $(docker ps -q)` as habits does more harm than good.
Compose is the default here; Sail is one variant.

## Compose is the default

Most repos run plain Docker Compose with an `app` or named service; a stock Laravel Sail repo's
service is `laravel.test`. **Take the exec prefix from the repo's `CLAUDE.md` COMMANDS table —
never from memory**, and never write a literal `docker compose exec app` into a shared
document.

Sail's `./vendor/bin/sail` works without the shell alias. The alias does not exist in an
agent session; use the path.

## Port registry

One row per repo, committed. Ports are **assigned here, not discovered at runtime** — a
registry is what prevents the collisions dynamic discovery creates. Check each row against the
repo's `docker-compose.yml` when you add or change a service.

| Repo | Web | Vite | Database | Redis | Mailpit SMTP / UI | Other |
| --- | --- | --- | --- | --- | --- | --- |
| example-site | 8000 (`APP_PORT`) | — | — (SQLite file) | — | — | Flask dev server 5000 outside Docker |
| example-api | 8010 (`APP_PORT`) | — | — | — | — | `npm run dev` on 8000 outside Docker |

Both examples default `APP_PORT` to 8000; example-api is assigned 8010 so both can run in
Docker at once. Set `APP_PORT=8010` in its environment until its default is changed.

### Collisions to watch for

In rough order of how likely they are to bite:

1. **Two repos binding the same host port** — typically a database port copied from one
   compose file into another. Neither can start while the other runs.
2. **A repo binding a host default** — 3306 (MySQL), 5432 (Postgres), 6379 (Redis). Any local
   service, or any other repo falling back to the default, conflicts.
3. **Ports that live only in a private `.env`**, with no literal values in a committed compose
   file. The registry cannot be verified against them, which is itself worth fixing.

### Ranges for anything new

Web 8000–8099 · Vite 5170–5199 · MySQL 33061–33099 · Postgres 54321–54399 · Redis
6380–6399 · Mailpit SMTP 1025–1049, UI 8025–8049. **Host defaults (80, 3306, 5432, 6379,
5173) are never used.** Add the row here in the same commit that adds the service.

## Conventions

- Container names `{repo}-{service}`: `example-site-app`, `example-api-app`. Compose will not start two
  containers with the same name, so this is load-bearing, not cosmetic.
- Only the host side of a port mapping changes. Container-internal ports (3306, 6379, 80)
  stay at their defaults — `"33061:3306"`, never `"33061:33061"`.
- `FORWARD_*` variables carry the host port in Sail repos.

## Commands that are not habits

The previous version listed these under "Best Practices". They are not.

| Command | What it actually does |
| --- | --- |
| `sail down -v` / `docker compose down -v` | **Deletes the database volume.** Non-negotiable 2 applies: dump first if the data matters. |
| `docker system prune -a` | Removes every unused image, including ones another repo needs; the next start is a full rebuild. |
| `docker stop $(docker ps -q)` | Stops every container on the machine, including other people's work. |

Stop one project with `docker compose down` (no `-v`), or `docker compose stop` to keep the
containers. To reclaim space, name what you are removing.

## When a container will not start

Check, in this order: is the port already bound (`lsof -i :PORT`), is a container of that
name already present but stopped (`docker ps -a`), is the database still starting (it
accepts connections a few seconds after the container reports healthy). A port conflict is
the answer most of the time, and the registry above is how you avoid re-diagnosing it.
