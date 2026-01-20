# Tailwind Plus Elements Integration

Panda Core includes automatic support for [Tailwind Plus Elements](https://tailwindcss.com/blog/vanilla-js-support-for-tailwind-plus), a vanilla JavaScript library that provides fully functional, accessible interactive UI components without requiring a JavaScript framework.

## Overview

Tailwind Plus Elements uses web standards including custom elements, the Popover API, native dialog elements, and ElementInternals to create robust, accessible interactive components. The library includes polyfills for broader browser compatibility.

## Available Components

The library provides eight foundational primitives:

- **Autocomplete** — Custom combobox implementations with search
- **Command palette** — Searchable command interfaces (⌘K style)
- **Dialog** — Modals, drawers, and overlays
- **Disclosure** — Collapsible sections and mobile menus
- **Dropdown menu** — Context menus and option selectors
- **Popover** — Floating UI elements with smart positioning
- **Select** — Custom dropdown selects with full keyboard support
- **Tabs** — Tabbed interfaces with ARIA support

## Installation & Usage

Tailwind Plus Elements is pre-configured in Panda Core's importmap. Choose one of the following methods to load it:

### Option 1: Direct CDN (Recommended)

The simplest approach - add this script tag to your HTML layout:

```html
<script src="https://cdn.jsdelivr.net/npm/@tailwindplus/elements@1" type="module"></script>
```

**Benefits:** Fastest to set up, cached across sites, no build step needed.

### Option 2: Import via JavaScript

Import in your application JavaScript file:

```javascript
// In your application.js or similar
import "panda/core/tailwindplus-elements"
```

This will load the library from the configured importmap (using esm.sh CDN).

### Option 3: Lazy Load

Load only when needed (great for performance):

```javascript
// Load when component is needed
import("panda/core/tailwindplus-elements").then(() => {
  // Elements are now available
  console.log("Tailwind Plus Elements loaded")
})
```

### Option 4: Self-Host

For production environments, you may want to self-host:

1. Install via npm: `npm install @tailwindplus/elements`
2. Build and serve the module with your asset pipeline
3. Update importmap to point to your hosted version

**Note:** A commercial license is required to use Tailwind Plus Elements. Purchase [Tailwind Plus](https://tailwindui.com/plus) to obtain a license.

## Usage with ViewComponent

Tailwind Plus Elements work seamlessly with ViewComponent components. The custom elements handle all the JavaScript behavior automatically.

### Example: Dropdown Menu

```ruby
class MyDropdownComponent < ViewComponent::Base
  erb_template <<~ERB
    <div class="relative inline-block text-left">
      <!-- Dropdown trigger button -->
      <button
        type="button"
        popovertarget="my-dropdown"
        class="inline-flex justify-center w-full rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-sm font-medium text-gray-700 hover:bg-gray-50">
        Options
        <!-- Chevron icon -->
        <svg class="ml-2 -mr-1 h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
          <path
            fill-rule="evenodd"
            d="M5.23 7.21a.75.75 0 011.06.02L10 11.168l3.71-3.938a.75.75 0 111.08 1.04l-4.25 4.5a.75.75 0 01-1.08 0l-4.25-4.5a.75.75 0 01.02-1.06z"
            clip-rule="evenodd" />
        </svg>
      </button>

      <!-- Dropdown menu (custom element) -->
      <el-popover
        id="my-dropdown"
        popover="auto"
        class="mt-2 w-56 origin-top-right rounded-md bg-white shadow-lg ring-1 ring-black ring-opacity-5">
        <el-menu role="menu" class="py-1">
          <el-menu-item role="menuitem">
            <a href="#" class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100">
              Account settings
            </a>
          </el-menu-item>
          <el-menu-item role="menuitem">
            <a href="#" class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100">
              Support
            </a>
          </el-menu-item>
          <el-menu-item role="menuitem">
            <a href="#" class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100">
              Sign out
            </a>
          </el-menu-item>
        </el-menu>
      </el-popover>
    </div>
  ERB
end
```

### Example: Dialog/Modal

```ruby
class MyModalComponent < ViewComponent::Base
  def initialize(id: "my-dialog", title:, trigger_text: "Open Dialog")
    @id = id
    @title = title
    @trigger_text = trigger_text
  end

  erb_template <<~ERB
    <!-- Trigger button -->
    <button
      type="button"
      popovertarget="<%= @id %>"
      class="rounded-md bg-blue-600 px-3 py-2 text-sm font-semibold text-white hover:bg-blue-500">
      <%= @trigger_text %>
    </button>

    <!-- Dialog element -->
    <el-dialog id="<%= @id %>" class="rounded-lg bg-white p-6 shadow-xl">
      <h3 class="text-lg font-medium text-gray-900 mb-4"><%= @title %></h3>

      <!-- Dialog content -->
      <%= content %>

      <!-- Close button -->
      <div class="mt-6 flex justify-end gap-3">
        <button
          type="button"
          popovertarget="<%= @id %>"
          popovertargetaction="hide"
          class="rounded-md bg-white px-3 py-2 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50">
          Cancel
        </button>
        <button
          type="button"
          class="rounded-md bg-blue-600 px-3 py-2 text-sm font-semibold text-white hover:bg-blue-500">
          Confirm
        </button>
      </div>
    </el-dialog>
  ERB
end
```

### Example: Disclosure (Collapsible)

```ruby
class MyDisclosureComponent < ViewComponent::Base
  def initialize(title:, expanded: false)
    @title = title
    @expanded = expanded
  end

  erb_template <<~ERB
    <el-disclosure class="border-b border-gray-200">
      <el-disclosure-button class="flex w-full items-center justify-between py-4 text-left">
        <span class="text-base font-semibold text-gray-900"><%= @title %></span>
        <svg
          class="h-5 w-5 text-gray-500 transition-transform duration-200"
          viewBox="0 0 20 20"
          fill="currentColor">
          <path
            fill-rule="evenodd"
            d="M5.23 7.21a.75.75 0 011.06.02L10 11.168l3.71-3.938a.75.75 0 111.08 1.04l-4.25 4.5a.75.75 0 01-1.08 0l-4.25-4.5a.75.75 0 01.02-1.06z"
            clip-rule="evenodd" />
        </svg>
      </el-disclosure-button>

      <el-disclosure-panel class="pb-4 text-sm text-gray-600">
        <%= content %>
      </el-disclosure-panel>
    </el-disclosure>
  ERB
end
```

### Example: Select

```ruby
class MySelectComponent < ViewComponent::Base
  def initialize(name:, options:, selected: nil)
    @name = name
    @options = options
    @selected = selected
  end

  erb_template <<~ERB
    <el-select name="<%= @name %>" class="relative">
      <el-select-button
        class="relative w-full cursor-default rounded-md bg-white py-2 pl-3 pr-10 text-left text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300">
        <span class="block truncate"><%= @selected || "Select an option" %></span>
        <span class="pointer-events-none absolute inset-y-0 right-0 flex items-center pr-2">
          <!-- Chevron icon -->
        </span>
      </el-select-button>

      <el-select-options
        class="absolute z-10 mt-1 max-h-60 w-full overflow-auto rounded-md bg-white py-1 shadow-lg ring-1 ring-black ring-opacity-5">
        <% @options.each do |option| %>
          <el-select-option
            value="<%= option[:value] %>"
            class="relative cursor-default select-none py-2 pl-3 pr-9 hover:bg-blue-600 hover:text-white">
            <span class="block truncate"><%= option[:label] %></span>
          </el-select-option>
        <% end %>
      </el-select-options>
    </el-select>
  ERB
end
```

## Features

### Automatic Behavior

Tailwind Plus Elements handle complex behaviors automatically:

- **ARIA attributes** — Proper accessibility markup
- **Focus management** — Keyboard navigation and focus trapping
- **Keyboard shortcuts** — Standard keyboard interactions
- **Position management** — Smart positioning for popovers/dropdowns
- **Animation** — Smooth transitions and animations

### Browser Support

The library includes polyfills and supports the same browsers as Tailwind CSS v4.0:

- Chrome/Edge (modern)
- Firefox (modern)
- Safari (modern)

## Best Practices

1. **Semantic HTML** — Use semantic HTML elements where possible
2. **Accessibility** — The elements handle ARIA, but ensure your content is accessible
3. **Progressive Enhancement** — Components work with JavaScript disabled (where applicable)
4. **Styling** — Use Tailwind CSS classes for consistent styling
5. **Testing** — Elements work in Capybara/system tests like normal HTML

## Resources

- [Tailwind Plus Elements Blog Post](https://tailwindcss.com/blog/vanilla-js-support-for-tailwind-plus)
- [Tailwind UI Plus Components](https://tailwindui.com/plus)
- [Custom Elements Documentation](https://developer.mozilla.org/en-US/docs/Web/API/Web_components/Using_custom_elements)
- [Popover API Documentation](https://developer.mozilla.org/en-US/docs/Web/API/Popover_API)

## Troubleshooting

### Elements not working

1. Ensure the library is loaded in your JavaScript:
   ```javascript
   import "panda/core/tailwindplus-elements"
   ```

2. Check browser console for errors

3. Verify the CDN is accessible (if using CDN mode)

### Styling issues

1. Ensure Tailwind CSS is properly configured
2. Check for class name conflicts
3. Verify dark mode classes if using dark mode

### Testing issues

In Capybara tests, the custom elements work like normal HTML:

```ruby
# In RSpec system test
visit my_page_path

# Click dropdown trigger
click_button "Options"

# Select menu item
click_link "Account settings"

# Check dialog
click_button "Open Dialog"
expect(page).to have_content("Dialog Title")
```

## Migration from Stimulus/Hotwire

If you're using Stimulus components for similar functionality:

1. **Dropdowns** — Replace Stimulus dropdown controllers with `<el-dropdown>`
2. **Modals** — Replace Stimulus modal controllers with `<el-dialog>`
3. **Tabs** — Replace Stimulus tabs controllers with `<el-tabs>`

Benefits:

- Less JavaScript code to maintain
- Better accessibility out of the box
- Native browser features
- Smaller bundle size
