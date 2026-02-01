# UI Elements (Admin)

This document summarizes the shared admin UI elements and how to use them consistently across Panda Core, Panda CMS, Panda CMS Pro, Panda Helpdesk, and Panda Editor.

## Buttons

Use `Panda::Core::Admin::ButtonComponent` for primary actions. It supports action styles (`:save`, `:create`, `:secondary`, `:danger`) and size variants (`:sm`, `:md`, `:lg`).

Example:

```erb
<%= render Panda::Core::Admin::ButtonComponent.new(text: "Add Page", action: :create) %>
<%= render Panda::Core::Admin::ButtonComponent.new(text: "Cancel", action: :secondary) %>
```

Guidelines:
- Primary action is a filled button.
- Secondary action is outlined.
- Destructive action is red-tinted.
- Use `+` for new/create actions (handled automatically when `action: :create`).

## Flash + Toast Messages

Use `Panda::Core::Admin::FlashMessageComponent` for temporary notifications.

Kinds supported:
- `:success`
- `:warning`
- `:error` (or `:alert`)
- `:info` / `:notice`

Example:

```erb
<%= render Panda::Core::Admin::FlashMessageComponent.new(kind: :success, message: "Saved.") %>
<%= render Panda::Core::Admin::FlashMessageComponent.new(kind: :info, message: "Analytics changes apply on refresh.") %>
```

Close buttons should always display text plus an X icon ("Close x").

## Callouts (Inline Notices)

Use `Panda::Core::Admin::CalloutComponent` for static, inline guidance within forms and settings pages.

```erb
<%= render Panda::Core::Admin::CalloutComponent.new(kind: :warning, text: "Define at least one field.") %>
<%= render Panda::Core::Admin::CalloutComponent.new(kind: :info, title: "Template snippet") do %>
  <pre class="rounded-xl bg-slate-900/95 p-3 text-xs text-emerald-200"><code>...</code></pre>
<% end %>
```

## Empty States

Use `Panda::Core::Admin::EmptyStateComponent` for list/table empty states.

```erb
<%= render Panda::Core::Admin::EmptyStateComponent.new(
  title: "No items yet",
  description: "Create your first item to get started.",
  icon: "fa-regular fa-folder-open"
) %>
```

## Code Blocks

Use `Panda::Core::Admin::CodeBlockComponent` for preformatted snippets.

```erb
<%= render Panda::Core::Admin::CodeBlockComponent.new do %>
<%% panda_cms_collection_items("people").each do |item| %>
  &lt;h3&gt;<%%= item.value_for("name") %>&lt;/h3&gt;
<%% end %>
<% end %>
```

Use this component for JSON-style fields (for example, service account credentials) so content reads as preformatted code.

## Form Fields

Inputs and selects are standardized with `rounded-xl`, consistent height, and neutral backgrounds.

- Inputs: `Panda::Core::Admin::FormInputComponent`
- Selects: `Panda::Core::Admin::FormSelectComponent`

Example:

```erb
<%= render Panda::Core::Admin::FormInputComponent.new(name: "title", placeholder: "Title") %>
<%= render Panda::Core::Admin::FormSelectComponent.new(name: "status", prompt: "Status", options: [["Hidden", "hidden"], ["Published", "published"]]) %>
```

Checkboxes/radios are sized to `h-5 w-5` and aligned vertically.

## Tags / Badges

Use `Panda::Core::Admin::TagComponent` for statuses and types.

Example:

```erb
<%= render Panda::Core::Admin::TagComponent.new(status: :active) %>
<%= render Panda::Core::Admin::TagComponent.new(page_type: :hidden_type) %>
```

## Tables

`Panda::Core::Admin::TableComponent` renders a modern table with rounded corners, aligned rows, and consistent header styling. Empty states render `EmptyStateComponent`.

## Panels + Sections

- `Panda::Core::Admin::PanelComponent` — use for card-like sections with optional header.
- `Panda::Core::Admin::FormSectionComponent` — use for grouping related form fields with a small heading.

## Navigation

Top-level and nested nav items use consistent spacing and no extra indentation. Nested items appear as a grouped list with clear separation.

## Slideover / Drawer

Slideover headers should include a visible "Close x" control (not icon-only).

---

For the latest visual reference, see `docs/ui-previews/admin-modern.html`.
