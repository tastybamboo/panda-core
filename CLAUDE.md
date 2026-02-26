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
