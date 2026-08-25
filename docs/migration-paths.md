# Migration paths: `db:migrate` and `db:schema:load` must agree

A Rails app can be provisioned two ways, and they read completely different files:

| | Reads | Used by |
|---|---|---|
| `db:schema:load` | `spec/dummy/db/schema.rb` | CI, most fresh dev checkouts, `db:prepare` on an empty database |
| `db:migrate` | `db/migrate/*.rb`, in order | deploys, and anyone who provisions the hard way |

Nothing about running one proves anything about the other. panda-core's CI ran
`db:create db:schema:load` in every job, so **no CI job had ever executed the
migrations in order against an empty database**. They diverged, twice, silently.

`bin/verify-migration-paths` now closes that gap and runs as the `migration-paths`
job in CI. Run it locally with:

```bash
bin/verify-migration-paths
```

## What it checks

It migrates from empty twice, as two different kinds of host app, and asserts:

1. **The bigint host's schema dump matches the committed `spec/dummy/db/schema.rb`
   exactly.** This is the assertion that matters. If a migration is edited without
   regenerating the schema, or a schema is hand-edited, the job fails.
2. **`panda_core_file_categorizations.blob_id` has the same type as
   `active_storage_blobs.id`**, in both hosts.
3. **`active_storage_attachments.record_id` is a string**, in both hosts.
4. **The polymorphic `tenant_id` columns are strings**, in both hosts.
5. The two hosts really do build different Active Storage tables — otherwise the
   uuid scenario would be silently testing nothing.

If assertion 1 fails after a deliberate migration change, regenerate and commit:

```bash
bin/rails db:drop db:create db:migrate   # dumps spec/dummy/db/schema.rb
```

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
