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
PORT=3001 bin/dev
bin/vite dev
```

`bin/dev` currently starts Rails only. Use `PORT=3001` if another local app is
already using `localhost:3000`. Run Vite separately for Inertia/React assets at
`localhost:3036`.

Run Sidekiq separately when testing background extraction jobs:

```bash
bundle exec sidekiq
```

## Environment variables

Create a `.env` file in the project root (or set these in your shell):

| Variable | Description |
|---|---|
| `DATABASE_URL` | PostgreSQL connection URL (optional — falls back to `config/database.yml`) |
| `REDIS_URL` | Redis connection URL (default: `redis://localhost:6379/0`) |
| `SECRET_KEY_BASE` | Rails secret key (auto-generated in dev via credentials) |
| `MASTER_AGREEMENT_EXTRACTION_ENDPOINT` | HTTPS endpoint for the AI contract extraction service |
| `MASTER_AGREEMENT_EXTRACTION_API_KEY` | Optional bearer token for the extraction endpoint |
| `MASTER_AGREEMENT_EXTRACTION_MODEL` | Optional provider model/deployment name for contract extraction |

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
npm run build
```

## Backoffice

Available at `/admin`. Requires a user with `superadmin: true`.
Used to create organizations and assign users to them.

## Architecture

Agora has three core layers:

- a template layer for organization-owned workflow phases, document templates,
  dependencies, fields, and source-of-truth rules;
- a contract packet/extraction layer for master agreement PDFs, AI extraction,
  review state, schedules, contacts, delivery locations, pricing rows, and
  clauses;
- a runtime shipment layer for purchase orders, shipments, shipment documents,
  field values, dependencies, and source-of-truth checks.

Read:

- [Architecture](docs/architecture.md)
- [Operational workflow](docs/operational-workflow.md)
- [Master agreement extraction](docs/master-agreement-extraction.md)
