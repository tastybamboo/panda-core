# CLAUDE.md

This file provides guidance to Claude Code when working with panda-core.

**Parent:** See `~/Projects/panda/CLAUDE.md` for monorepo-wide rules (CSS compilation, JS architecture, API security, ViewComponent requirements).

## Project Overview

Panda Core is a lightweight Rails engine that provides shared development tools, configurations, and utilities for Panda CMS and other panda-* gems. It serves as the foundation dependency that other Panda ecosystem gems build upon.

**Core Structure:**
- **Rails Engine**: `lib/panda/core/engine.rb`
- **Configuration**: Uses `dry-configurable` for flexible settings in `lib/panda/core.rb`
- **Services**: Base service pattern in `lib/panda/core/services/base_service.rb`
- **Utilities**: SEO helpers, media handling, sluggable concern, OAuth providers

For architecture proposals and migration plans, see [docs/architecture-proposal.md](docs/architecture-proposal.md).

## Development Workflow

The dummy Rails application in `spec/dummy` provides the test environment for the engine. When running Rails tasks:
- Change to `spec/dummy` directory first
- Run commands like `bundle exec rspec`, `rails db:migrate`, etc. from there
- The dummy app's database configuration supports both PostgreSQL (default) and SQLite (via `DATABASE_ADAPTER=sqlite` env var)

### Database provisioning: `db:migrate` and `db:schema:load` are not the same

`db:schema:load` reads `spec/dummy/db/schema.rb` and never enumerates
`db/migrate`; deploys do the opposite. Nothing about running one proves anything
about the other, and they have diverged silently before.

Two CI jobs cover it, because the default host app and a host app that sets
`primary_key_type: :uuid` legitimately build different schemas:

```bash
# schema job — replays the migrations and diffs the dump against schema.rb
DATABASE_URL=postgres://localhost/panda_core_schema_check \
  bundle exec rails db:drop db:create app:panda:core:schema:check

# uuid-host job — migrates from empty as a uuid host and checks consistency
bin/verify-uuid-host-migrations
```

Two rules follow from them:

- **After changing a migration, regenerate and commit the schema** — `bin/rails
  db:drop db:create db:migrate` **from the repository root** dumps
  `spec/dummy/db/schema.rb`. Do not run `db:migrate` from inside `spec/dummy`:
  the engine's migrations are not on the path there, and the dump silently
  overwrites `schema.rb` with a version missing every `panda_core_*` table.
- **Editing a released migration only fixes databases that do not exist yet.** If
  deployed databases are also wrong, they need a *new* migration.

Active Storage primary keys are the host app's decision, not this gem's: Rails'
own `CreateActiveStorageTables` reads `Rails.configuration.generators` at
migration time, so a host that sets `primary_key_type: :uuid` gets uuid blob ids
and one that does not gets bigint. panda-core migrations must read that type
rather than assume one. See [docs/migration-paths.md](docs/migration-paths.md).

### Database Support

Panda Core supports both PostgreSQL and SQLite3 for development and testing:

**PostgreSQL (default):**
```bash
bundle exec rails db:create db:migrate
bundle exec rspec
```

**SQLite3:**
```bash
DATABASE_ADAPTER=sqlite bundle exec rails db:migrate
DATABASE_ADAPTER=sqlite bundle exec rspec
```

**Cross-Database UUID Support:**
- UUIDs work identically on both databases via the `HasUUID` concern
- PostgreSQL uses native `gen_random_uuid()` function
- SQLite uses `SecureRandom.uuid` at the application level
- All models with UUID primary keys automatically include `HasUUID`

## Code Quality Commands

```bash
# Run YAML linter
yamllint -c .yamllint .
```

- In this directory, always run tests from spec/dummy
