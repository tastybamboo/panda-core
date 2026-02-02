# Nested Navigation

Panda Core supports nested navigation items in the admin sidebar, allowing you to organize menu items hierarchically with expandable/collapsible parent items.

## Basic Usage

### Simple Navigation Items

Simple navigation items work as before:

```ruby
Panda::Core.configure do |config|
  config.admin_navigation_items = ->(user) {
    [
      {
        label: "Dashboard",
        path: "/admin",
        icon: "fa-solid fa-house"
      },
      {
        label: "Settings",
        path: "/admin/settings",
        icon: "fa-solid fa-gear"
      }
    ]
  }
end
```

### Nested Navigation Items

To create expandable menu items with children, omit the `path` and add a `children` array:

```ruby
Panda::Core.configure do |config|
  config.admin_navigation_items = ->(user) {
    [
      {
        label: "Dashboard",
        path: "/admin",
        icon: "fa-solid fa-house"
      },
      {
        label: "Team",
        icon: "fa-solid fa-users",
        children: [
          { label: "Overview", path: "/admin/team/overview" },
          { label: "Members", path: "/admin/team/members" },
          { label: "Calendar", path: "/admin/team/calendar" },
          { label: "Settings", path: "/admin/team/settings" }
        ]
      },
      {
        label: "Projects",
        icon: "fa-solid fa-folder",
        children: [
          { label: "All Projects", path: "/admin/projects" },
          { label: "Active", path: "/admin/projects/active" },
          { label: "Archived", path: "/admin/projects/archived" }
        ]
      }
    ]
  }
end
```

## Data Structure

### Parent Item with Children

```ruby
{
  label: "Team",                    # Required: Display text for the parent item
  icon: "fa-solid fa-users",        # Required: FontAwesome icon (fa-solid or fab only)
  children: [                       # Required: Array of child items
    { label: "...", path: "..." },  # Child items must have label and path
    # ...
  ]
}
```

**Note:** Parent items with children should NOT have a `path` attribute. They render as buttons, not links.

### Child Item

```ruby
{
  label: "Overview",          # Required: Display text for the child item
  path: "/admin/team/overview" # Required: URL path for the link
}
```

**Note:** Child items do not have icons. They are indented under their parent and styled consistently.

## Features

### Automatic Expansion

When a child item is active (matches the current path), the parent menu automatically expands on page load. This ensures users can see their current location in the navigation hierarchy.

### Active State Highlighting

- **Active child items**: Highlighted with the `bg-mid` background color
- **Parent with active child**: The parent button is also highlighted to show which section is active

### Path Matching

The navigation system uses intelligent path matching:

- Exact path matches (e.g., `/admin/team/members`)
- Prefix matches for nested routes (e.g., `/admin/team/members/123` matches `/admin/team/members`)
- Longest path wins when multiple items could match

### Accessibility

Nested navigation items include proper accessibility attributes:

- `aria-controls`: Links the button to its submenu
- `aria-expanded`: Indicates whether the submenu is expanded (`true`) or collapsed (`false`)
- Semantic HTML: Uses `<button>` for expandable items, `<a>` for links

## Icon Requirements

All icons must use FontAwesome Free classes:

- Use `fa-solid` for solid icons (most common)
- Use `fab` for brand icons (GitHub, Google, etc.)

**Example icons:**

```ruby
icon: "fa-solid fa-house"        # Dashboard
icon: "fa-solid fa-users"        # Team
icon: "fa-solid fa-folder"       # Projects
icon: "fa-solid fa-file"         # Pages
icon: "fa-solid fa-newspaper"    # Posts
icon: "fa-solid fa-gear"         # Settings
icon: "fab fa-github"            # GitHub (brand icon)
```

## JavaScript Behavior

The navigation toggle behavior is handled by the `navigation-toggle` Stimulus controller, which provides:

- Click to expand/collapse
- Chevron icon rotation (→ rotates to ↓)
- Automatic expansion when a child is active
- Support for multiple expanded menus simultaneously

No additional JavaScript configuration is required.

## Examples

### Content Management System

```ruby
config.admin_navigation_items = ->(user) {
  items = [
    {
      label: "Dashboard",
      path: "/admin/cms",
      icon: "fa-solid fa-house"
    },
    {
      label: "Content",
      icon: "fa-solid fa-file-lines",
      children: [
        { label: "Pages", path: "/admin/cms/pages" },
        { label: "Posts", path: "/admin/cms/posts" },
        { label: "Media", path: "/admin/cms/media" }
      ]
    },
    {
      label: "Settings",
      icon: "fa-solid fa-gear",
      children: [
        { label: "General", path: "/admin/cms/settings" },
        { label: "SEO", path: "/admin/cms/settings/seo" },
        { label: "Navigation", path: "/admin/cms/menus" }
      ]
    }
  ]

  items
}
```

### User-Specific Navigation

You can use the `user` parameter to customize navigation based on permissions:

```ruby
config.admin_navigation_items = ->(user) {
  items = [
    {
      label: "Dashboard",
      path: "/admin",
      icon: "fa-solid fa-house"
    }
  ]

  # Only show team management to admins
  if user.admin?
    items << {
      label: "Team",
      icon: "fa-solid fa-users",
      children: [
        { label: "Members", path: "/admin/team/members" },
        { label: "Roles", path: "/admin/team/roles" },
        { label: "Permissions", path: "/admin/team/permissions" }
      ]
    }
  end

  items
}
```

## Migration from Simple Navigation

If you're updating existing navigation to use nested items:

**Before:**

```ruby
config.admin_navigation_items = ->(user) {
  [
    { label: "Dashboard", path: "/admin", icon: "fa-solid fa-house" },
    { label: "Team Overview", path: "/admin/team/overview", icon: "fa-solid fa-users" },
    { label: "Team Members", path: "/admin/team/members", icon: "fa-solid fa-users" },
    { label: "Team Calendar", path: "/admin/team/calendar", icon: "fa-solid fa-users" }
  ]
}
```

**After:**

```ruby
config.admin_navigation_items = ->(user) {
  [
    { label: "Dashboard", path: "/admin", icon: "fa-solid fa-house" },
    {
      label: "Team",
      icon: "fa-solid fa-users",
      children: [
        { label: "Overview", path: "/admin/team/overview" },
        { label: "Members", path: "/admin/team/members" },
        { label: "Calendar", path: "/admin/team/calendar" }
      ]
    }
  ]
}
```

## Extending Navigation from Gems

Panda gems can extend the admin navigation by wrapping the existing `admin_navigation_items` lambda in an engine initializer. This allows multiple gems to contribute navigation items independently.

### Adding a New Section

Wrap the existing lambda and insert your items at the desired position:

```ruby
# In your engine's core_config.rb or engine.rb
initializer "panda_helpdesk.configure_core", before: :load_config_initializers do |app|
  Panda::Core.configure do |config|
    original_nav = config.admin_navigation_items

    config.admin_navigation_items = ->(user) {
      items = original_nav.respond_to?(:call) ? original_nav.call(user) : []
      admin_path = config.admin_path

      # Insert before a specific item by label
      settings_index = items.index { |i| i[:label] == "Settings" }
      items.insert(settings_index || items.length, {
        label: "Helpdesk",
        icon: "fa-solid fa-headset",
        children: [
          {label: "Tickets", path: "#{admin_path}/helpdesk/tickets"},
          {label: "Reports", path: "#{admin_path}/helpdesk/reports"}
        ]
      })

      items
    }
  end
end
```

### Adding Children to an Existing Group

Multiple gems can add children to the same group (e.g. Settings). Use the merge pattern — expand the item from flat to group if it hasn't been expanded yet, then append your children:

```ruby
config.admin_navigation_items = ->(user) {
  items = original_nav.respond_to?(:call) ? original_nav.call(user) : []
  admin_path = config.admin_path

  settings_item = items.find { |i| i[:label] == "Settings" }
  if settings_item
    # Expand from flat link to group if this gem is first to add children
    unless settings_item.key?(:children)
      original_path = settings_item.delete(:path)
      settings_item[:children] = [
        {label: "General", path: original_path}
      ]
    end

    # Append your children — safe regardless of ordering
    settings_item[:children] << {label: "Helpdesk", path: "#{admin_path}/helpdesk/settings"}
  end

  items
}
```

**Important:** Always use `find` + merge rather than replacing the item entirely. This ensures multiple gems can independently add children to the same group without overwriting each other, regardless of initializer execution order.

### Positioning with `insert`

Use Ruby's `Array#insert` with a label-based index lookup to control where items appear:

```ruby
# Insert before Settings
idx = items.index { |i| i[:label] == "Settings" }
items.insert(idx || items.length, new_item)

# Insert after Tools
idx = items.index { |i| i[:label] == "Tools" }
items.insert((idx || items.length - 1) + 1, new_item)

# Append to the end (simplest)
items << new_item
```

### Initializer Ordering

Gems wrap each other's lambdas, so execution order is **innermost first** (first registered = first executed). For most use cases this doesn't matter because:

- Inserting by label works regardless of order
- The merge pattern for adding children is order-independent
- Use `before: :load_config_initializers` for standard engine configuration
- Use `after: "panda.cms.configure_core"` if you need CMS items to exist first

## Best Practices

1. **Limit nesting depth**: Only one level of nesting is supported (parent → children). Do not nest children within children.

2. **Group related items**: Use nested navigation to group related functionality under a common parent.

3. **Clear labels**: Use concise, descriptive labels for both parent and child items.

4. **Icon selection**: Choose icons that clearly represent the parent category.

5. **Logical ordering**: Order items by frequency of use or logical grouping.

6. **Consistent naming**: Use consistent terminology across parent and child items.

## Technical Details

### File Locations

- **Sidebar component**: `app/components/panda/core/admin/sidebar_component.html.erb`
- **Stimulus controller**: `app/javascript/panda/core/controllers/navigation_toggle_controller.js`
- **Tests**: `spec/system/panda/core/admin/nested_navigation_spec.rb`

### Stimulus Controller

The `navigation-toggle` controller is automatically registered and handles:

- Toggling visibility of submenu
- Rotating chevron icon
- Managing `aria-expanded` attribute
- Auto-expanding when child is active

### Styling

Nested navigation uses Tailwind CSS classes:

- Parent buttons: Same styling as regular navigation items
- Child links: Indented with `pl-11` (44px left padding)
- Active states: `bg-primary-500/20 text-white` for both parent and child
- Expanded section: `bg-white/10` wrapper with `bg-white/15` header
- Transitions: CSS `max-h` + opacity transitions for smooth expand/collapse

## Troubleshooting

### Children Not Showing

Check that:

1. Parent item has `children` array defined
2. Parent item does NOT have a `path` (it should be a button, not a link)
3. Each child has both `label` and `path`

### JavaScript Not Working

Ensure:

1. Stimulus is properly loaded
2. `navigation-toggle` controller is registered
3. JavaScript is enabled in your browser
4. No JavaScript errors in console

### Active State Not Working

Verify:

1. Child paths match your actual routes
2. Current path is being compared correctly
3. Path matching includes both exact and prefix matches
