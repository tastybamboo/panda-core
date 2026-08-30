# Migration paths: `db:migrate` and `db:schema:load` must agree

A Rails app can be provisioned two ways, and they read completely different files:

| | Reads | Used by |
|---|---|---|
| `db:schema:load` | `spec/dummy/db/schema.rb` | CI, most fresh dev checkouts, `db:prepare` on an empty database |
| `db:migrate` | `db/migrate/*.rb`, in order | deploys, and anyone who provisions the hard way |

Nothing about running one proves anything about the other. panda-core's CI ran
`db:create db:schema:load` in every job, so **no CI job had ever executed the
migrations in order against an empty database**. They diverged, twice, silently.

Two CI jobs now close that gap, because one check cannot cover both kinds of
host application:

| Job | Task | Covers |
|---|---|---|
| `schema` | `panda:core:schema:check` | The **default** host. Replays every migration into an empty database and diffs the dump against the committed `spec/dummy/db/schema.rb`. Also refuses duplicate migration versions. |
| `uuid-host` | `bin/verify-uuid-host-migrations` | A host that sets `primary_key_type: :uuid`. It legitimately builds a *different* schema, so there is no `schema.rb` to compare against — the job asserts internal consistency instead. |

Run them locally with:

```bash
DATABASE_URL=postgres://localhost/panda_core_schema_check \
  bundle exec rails db:drop db:create app:panda:core:schema:check
bin/verify-uuid-host-migrations
```

The `uuid-host` job asserts that `panda_core_file_categorizations.blob_id` has
the same type as `active_storage_blobs.id`, that
`active_storage_attachments.record_id` is a string, and that the polymorphic
`tenant_id` columns are strings. Reverting the `blob_id` fix below fails it with
the original `DatatypeMismatch` while `panda:core:schema:check` stays green —
which is exactly why both jobs exist.

## Regenerating the schema: mind the working directory

`bin/rails` at the **repository root** sets `ENGINE_PATH`, so the engine's
`db/migrate` is on the migration path. From there `db:migrate` runs all 32
migrations and dumps a correct `spec/dummy/db/schema.rb`:

```bash
bin/rails db:drop db:create db:migrate
```

`spec/dummy/bin/rails` does **not**. From inside `spec/dummy` only that app's own
three migrations run — no `panda_core_*` tables at all — and the dump silently
overwrites `schema.rb` with a version missing every engine table. CLAUDE.md tells
you to run Rails tasks from `spec/dummy`; for `db:migrate` specifically, do not.

## Why there are two kinds of host app

`config.generators { |g| g.orm :active_record, primary_key_type: :uuid }` is an
application-level setting, and Rails' own `CreateActiveStorageTables` and
`CreateActionTextTables` read it **at migration time**:

```ruby
def primary_and_foreign_key_types
  config = Rails.configuration.generators
  setting = config.options[config.orm][:primary_key_type]
  [setting || :primary_key, setting || :bigint]
end
```

So in an app that sets it — Alder CRM does, in `config/application.rb` — a fresh
`db:migrate` builds `active_storage_blobs.id`,
`active_storage_attachments.id`/`.blob_id` and
`active_storage_variant_records.id`/`.blob_id` as **uuid**. In an app that does
not, they are **bigint**. Both are legitimate, and it is entirely the host app's
decision.

`Panda::Core::Engine` sets `primary_key_type: :uuid` too, but on
`config.generators`, which `Rails::Engine::Configuration` deep-copies from the
shared `app_generators` object. An engine's `config.generators` is its own; it
governs generators run inside the engine and never reaches
`Rails.configuration.generators`. **`config.app_generators` is the one that would
leak** — panda-core must not use it for `primary_key_type`, or it would silently
retype the host app's Active Storage tables. `spec/lib/panda/core/shared/generator_config_spec.rb`
asserts this in both directions.

The gem therefore has no opinion about host-app Active Storage primary keys. It
reads them.

## The two divergences this was written for

### `panda_core_file_categorizations.blob_id`

`CreatePandaCoreFileCategories` declared `t.bigint :blob_id` and added a foreign
key to `active_storage_blobs`. Correct in a bigint host; in a uuid host a fresh
`db:migrate` aborted:

```
PG::DatatypeMismatch: foreign key constraint "fk_rails_4c5a7f710a" cannot be implemented
DETAIL: Key columns "blob_id" and "id" are of incompatible types: bigint and uuid.
```

Changing it to `:uuid` would have inverted the problem and broken every existing
database, all of which have bigint blobs. The migration now reads the type of
`active_storage_blobs.id` out of the database it is running against, so it is
right in both. No existing database is affected: they all ran this migration long
ago, and a database where it succeeded necessarily has bigint blob ids and a
bigint `blob_id` to match.

### `active_storage_attachments.record_id`

`FixActiveStorageAttachmentsRecordIdType` converts `record_id` to a string so it
can hold host models' uuid primary keys. In a uuid host it hit two problems: its
`DELETE ... WHERE record_id = 0` cleanup is not well typed against a uuid column,
and PostgreSQL has no assignment cast from uuid to text, so `ALTER TABLE ... TYPE`
needs an explicit `USING`. Both are handled, and the integer-only cleanup now runs
only against integer columns. Its early-out also tested `sql_type ==
"character varying"`, which is PostgreSQL spelling; it tests the abstract
`column.type` now, so SQLite behaves the same way.

## The lesson that outlives both

`panda_core_tags.tenant_id` was `t.bigint` and #151 fixed it to `t.string` by
**editing the released migration in place**. That fixed exactly one thing: what a
fresh `db:migrate` builds. Every database that had already run the migration kept
its bigint column, `db:schema:load` kept building bigint because
`spec/dummy/db/schema.rb` was never regenerated, and nothing ever said so.

Editing a released migration only ever fixes databases that have not been built
yet. If existing databases are wrong, they need a **new** migration — see
`20260825120000_normalise_polymorphic_tenant_id_columns.rb`, which converts the
polymorphic `tenant_id` columns on `panda_core_tags` and
`panda_core_import_sessions` wherever they are still integers, and leaves string
and uuid columns (a host app that typed them itself) alone.
