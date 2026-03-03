# User Metadata

Panda Core users have a JSONB `metadata` column that stores arbitrary key-value data. The `HasMetadata` concern provides a DSL for declaring typed metadata fields with auto-generated scopes, predicates, and admin UI filters.

## Quick Start

The `metadata_field` macro on any model that includes `HasMetadata`:

```ruby
class User < ApplicationRecord
  include HasMetadata

  metadata_field :internal, type: :boolean, filterable: true,
    label: "Visibility", default_scope: :external,
    filter_options: [["All Users", ""], ["Staff Users", "internal"], ["External Users", "external"]]
end
```

This single declaration generates:

| Generated | Example |
|-----------|---------|
| True scope | `User.internal` |
| Default (false) scope | `User.external` |
| Predicate | `user.internal?` |
| Mark as true | `user.mark_as_internal!` |
| Mark as false | `user.mark_as_external!` |
| Virtual attribute | `user.internal = "1"` (for form checkboxes) |
| Reader | `user.internal` |

## `metadata_field` Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `type` | Symbol | `:boolean` | Field type. Only `:boolean` is supported currently. |
| `filterable` | Boolean | `false` | When `true`, the field appears in admin filter dropdowns. |
| `label` | String | Humanized key | Label for the filter dropdown header. |
| `default_scope` | Symbol | `not_<key>` | Scope name for the false/absent case. |
| `filter_options` | Array | `nil` | Array of `[label, value]` pairs for the dropdown. Values must match scope names. |

## Generic Metadata Access

Beyond declared fields, you can read/write arbitrary metadata:

```ruby
user.set_metadata("tier", "gold")       # persists immediately
user.metadata_value("tier")             # => "gold"
user.remove_metadata("tier")            # persists immediately

user.set_metadata_attribute("draft", true)  # in-memory only (no save)

User.with_metadata("tier", "gold")      # generic scope
```

## Admin Controller Integration

The controller uses `apply_metadata_filters` to apply all filterable metadata fields from request params:

```ruby
# In index action
@users = User.apply_metadata_filters(@users, params)
```

Filter values from `params` are validated against the `filter_options` whitelist — only declared option values are accepted. This prevents arbitrary scope calls.

## Admin View Integration

Filter dropdowns render dynamically from registered filterable fields:

```erb
<% User.filterable_metadata_fields.each do |key, config| %>
  <% bar.with_filter do %>
    <%= select_tag key,
      options_for_select(config[:filter_options], params[key.to_sym]),
      class: bar.select_classes %>
  <% end %>
<% end %>
```

Check if any metadata filter is active (for the clear button):

```erb
show_clear: ... || User.metadata_filter_active?(params)
```

## Adding a New Metadata Field

1. Add a `metadata_field` declaration to the model (no migration needed):

```ruby
metadata_field :beta_tester, type: :boolean, filterable: true,
  label: "Beta Program", default_scope: :stable,
  filter_options: [["All Users", ""], ["Beta Testers", "beta_tester"], ["Stable", "stable"]]
```

2. If admin editing is needed, add a checkbox to the edit form and permit the param.

3. The filter dropdown, scopes, and predicates are created automatically.

## Database Compatibility

- **PostgreSQL**: Uses `@>` containment operator with a GIN index for fast lookups.
- **SQLite**: Falls back to `json_extract()` functions. No GIN index (skipped in migration).

## Current Declared Fields

| Field | Type | Scopes | Purpose |
|-------|------|--------|---------|
| `internal` | boolean | `.internal` / `.external` | Exclude staff/test accounts from reports |
