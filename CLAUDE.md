# Agora

SaaS for export companies: trade document management and payment tracking.

## Stack

- **Rails 8** — backend, native auth (`has_secure_password`, sessions)
- **Inertia.js** — Rails ↔ React bridge, no separate REST layer
- **React + TypeScript** — frontend, one component per page in `app/frontend/pages/`
- **shadcn/ui + Tailwind v4** — UI components; files live in `app/frontend/components/ui/` (you own them, edit freely)
- **PostgreSQL** — database; `pgvector` for semantic search
- **Avo** — backoffice at `/admin`, own layout, independent from the React frontend
- **Pundit** — authorization
- **acts_as_tenant** — path-based multi-tenancy (`/:org_slug/...`), `organization_id` on every table
- **PaperTrail** — audit trail on critical models
- **Sidekiq + Redis** — background jobs
- **Render** — hosting

## Permissions (RBAC)

- `Permission(resource, action)` — app-defined permission catalog
- `Role` — belongs to an organization, has many permissions via `RolePermission`
- `User` — belongs directly to a `Role`
- `user.can?(resource, action)` → delegates to `role.permissions.exists?`
- Pundit policies use `permitted?(resource, action)` as the base check
- Roles are seeded automatically on org creation (`SeedOrganizationRoles`)
- Users with `superadmin: true` access Avo; they have no organization

## Avo (backoffice)

- Lives at `/admin` with its own layout — never inherits the app layout
- Auth: looks up session via cookie (`cookies.signed[:session_id]`), requires `user.superadmin?`
- Create users and organizations directly from Avo
- Logout handled via `app/views/avo/partials/_profile_menu_extra.html.erb`
- **Never include Vite assets in Avo's layout** — it breaks Avo's styles

## Frontend (Inertia + React)

- Each page is a component in `app/frontend/pages/PageName.tsx`
- Controllers render with `render inertia: "PageName", props: { ... }`
- `createInertiaApp` only runs when the Inertia script tag is present in the DOM (guard in `application.tsx`)
- To redirect to non-Inertia URLs (e.g. `/admin`) from an Inertia form, use `inertia_location url` in the controller
- shadcn CSS variables are scoped to `#app` to avoid overriding Avo's styles

## Testing

- Framework: **Minitest** (Rails native)
- Every new model → test in `test/models/`
- Every policy → test in `test/policies/`
- Every service → test in `test/services/`
- No database mocks — use fixtures against the real DB
- Run tests: `bin/rails test`

## UI text

All user-facing text (labels, buttons, messages, placeholders) must be in **Spanish**.
