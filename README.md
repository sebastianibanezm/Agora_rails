# Agora

## Requirements

- Ruby 3.3.6
- Node.js 20+
- PostgreSQL 14+
- Redis

## Setup

```bash
bin/setup
```

Installs dependencies, creates and migrates the database, and starts the dev server.

## Running

```bash
bin/dev
```

Starts Rails (`localhost:3000`), the Vite dev server (`localhost:3036`), and a Sidekiq worker together.

## Environment variables

Create a `.env` file in the project root (or set these in your shell):

| Variable | Description |
|---|---|
| `DATABASE_URL` | PostgreSQL connection URL (optional — falls back to `config/database.yml`) |
| `REDIS_URL` | Redis connection URL (default: `redis://localhost:6379/0`) |
| `SECRET_KEY_BASE` | Rails secret key (auto-generated in dev via credentials) |

Redis must be running locally for Sidekiq-backed background jobs.

## Create a superadmin

```bash
bin/rails console
User.create!(email_address: "you@example.com", password: "yourpassword", superadmin: true)
```

Then sign in at `localhost:3000/admin/login`.

## Tests

```bash
bin/rails test
```

## Backoffice

Available at `/admin`. Requires a user with `superadmin: true`.
Used to create organizations and assign users to them.

## Architecture

Agora has two core layers:

- a template layer for organization-owned workflow phases, document templates,
  dependencies, fields, and source-of-truth rules;
- a runtime layer for trading partners, contracts, purchase orders, shipments,
  shipment documents, field values, dependencies, and source-of-truth checks.

Read:

- [Architecture](docs/architecture.md)
- [Operational workflow](docs/operational-workflow.md)
