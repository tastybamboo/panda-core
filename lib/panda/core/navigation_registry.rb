# frozen_string_literal: true

module Panda
  module Core
    # Declarative registry for extending admin sidebar navigation.
    #
    # Gems and host apps register navigation sections and items at boot time,
    # and the registry merges them with the base +admin_navigation_items+ lambda
    # at render time. This avoids the fragile lambda-wrapping pattern where each
    # gem must capture the existing proc, create a new one, and manipulate the
    # resulting array with index lookups and insertions.
    #
    # == Path resolution
    #
    # * +path:+ — auto-prefixed with +admin_path+ (e.g. <tt>path: "feature_flags"</tt>
    #   becomes <tt>"/admin/feature_flags"</tt>)
    # * +url:+ — used as-is, for full URLs or absolute paths
    # * +target:+ — HTML target attribute (e.g. <tt>"_blank"</tt>), omitted when +nil+
    #
    # == Usage
    #
    # Convenience methods on {Panda::Core::Configuration} delegate here, so the
    # typical usage is inside a +Panda::Core.configure+ block:
    #
    #   # In a host app initializer or engine:
    #   Panda::Core.configure do |config|
    #     # Add a new section with items, positioned after "Website"
    #     config.insert_admin_menu_section "Members",
    #       icon: "fa-solid fa-users",
    #       after: "Website" do |section|
    #         section.item "Onboarding", path: "members/onboarding"
    #       end
    #
    #     # Add an item to an existing section
    #     config.insert_admin_menu_item "Feature Flags",
    #       section: "Settings",
    #       path: "feature_flags"
    #
    #     # Full URL with target (no prefix)
    #     config.insert_admin_menu_item "Documentation",
    #       section: "Help",
    #       url: "https://docs.example.com",
    #       target: "_blank"
    #   end
    #
    # You can also call the class methods directly:
    #
    #   Panda::Core::NavigationRegistry.section("Tools", icon: "fa-solid fa-wrench")
    #   Panda::Core::NavigationRegistry.item("Database", section: "Tools", path: "tools/database")
    #
    # == Build order
    #
    # {.build} is called once per request by the sidebar component:
    #
    # 1. The base +admin_navigation_items+ lambda is called (backward compatible)
    # 2. Registered sections are inserted (skipped if a section with the same label
    #    already exists in the base)
    # 3. Registered items are appended to their target sections
    #
    # Paths are resolved at build time, so +admin_path+ can be configured after
    # registrations are made.
    class NavigationRegistry
      # Collects items added inside a {.section} block.
      #
      # @example
      #   NavigationRegistry.section("Members", icon: "fa-solid fa-users") do |s|
      #     s.item "Onboarding", path: "members/onboarding"
      #     s.item "Directory", path: "members/directory"
      #   end
      class SectionContext
        attr_reader :items

        def initialize
          @items = []
        end

        # Register an item within this section.
        # @param label [String] Display label
        # @param path [String, nil] Relative path (auto-prefixed with admin_path at build time)
        # @param url [String, nil] Absolute URL (used as-is)
        # @param target [String, nil] HTML target attribute (e.g. "_blank")
        def item(label, path: nil, url: nil, target: nil)
          @items << {label: label, path: path, url: url, target: target}
        end
      end

      @sections = []
      @items = []

      class << self
        attr_reader :sections, :items

        # Register a new navigation section.
        #
        # If a section with the same label already exists in the base navigation
        # (from the +admin_navigation_items+ lambda), the registration is skipped
        # at build time — this prevents duplicate sections.
        #
        # @param label [String] Section label displayed in the sidebar
        # @param icon [String] FontAwesome icon class (e.g. "fa-solid fa-users")
        # @param after [String, nil] Insert after the section with this label
        # @param before [String, nil] Insert before the section with this label
        # @yield [SectionContext] Optional block for adding items to the section
        #
        # @example Add a section with items after "Website"
        #   section("Members", icon: "fa-solid fa-users", after: "Website") do |s|
        #     s.item "Onboarding", path: "members/onboarding"
        #   end
        #
        # @example Add an empty section (items added separately via .item)
        #   section("Tools", icon: "fa-solid fa-wrench")
        def section(label, icon: nil, after: nil, before: nil, &block)
          context = SectionContext.new
          yield context if block

          @sections << {
            label: label,
            icon: icon,
            after: after,
            before: before,
            items: context.items
          }
        end

        # Register an item to be appended to a named section.
        #
        # The target section can come from either the base lambda or a
        # previously registered section. If the section doesn't exist at
        # build time, the item is silently skipped.
        #
        # @param label [String] Item label displayed in the sidebar
        # @param section [String] Label of the target section to add to
        # @param path [String, nil] Relative path (auto-prefixed with admin_path)
        # @param url [String, nil] Absolute URL (used as-is, no prefixing)
        # @param target [String, nil] HTML target attribute (e.g. "_blank")
        #
        # @example Add to an existing section with auto-prefixed path
        #   item("Feature Flags", section: "Settings", path: "feature_flags")
        #
        # @example Add an external link
        #   item("Docs", section: "Help", url: "https://docs.example.com", target: "_blank")
        def item(label, section:, path: nil, url: nil, target: nil)
          @items << {label: label, section: section, path: path, url: url, target: target}
        end

        # Build the final navigation array for the current user.
        #
        # Called once per request by the sidebar component. Combines the base
        # +admin_navigation_items+ lambda with all registered sections and items.
        #
        # @param user [Object] The current authenticated user
        # @return [Array<Hash>] Navigation items ready for rendering
        def build(user)
          base = Panda::Core.config.admin_navigation_items&.call(user) || []
          admin_path = Panda::Core.config.admin_path

          # Apply registered sections
          @sections.each do |section|
            # Skip if a section with this label already exists in base
            next if base.any? { |item| item[:label] == section[:label] }

            entry = {label: section[:label], icon: section[:icon]}
            if section[:items].any?
              entry[:children] = section[:items].map { |item| resolve_item(item, admin_path) }
            end

            insert_section(base, entry, after: section[:after], before: section[:before])
          end

          # Apply registered items to their target sections
          @items.each do |item|
            target_section = base.find { |s| s[:label] == item[:section] }
            next unless target_section

            target_section[:children] ||= []
            target_section[:children] << resolve_item(item, admin_path)
          end

          base
        end

        # Clear all registrations (for test isolation).
        def reset!
          @sections = []
          @items = []
        end

        private

        # Resolve path: or url: into a final :path value, and include :target when present.
        def resolve_item(item, admin_path)
          resolved = {label: item[:label]}

          if item[:url]
            resolved[:path] = item[:url]
          elsif item[:path]
            resolved[:path] = "#{admin_path}/#{item[:path]}"
          end

          resolved[:target] = item[:target] if item[:target]
          resolved
        end

        # Insert a section entry into the base array at the correct position.
        def insert_section(base, entry, after: nil, before: nil)
          if after
            index = base.index { |item| item[:label] == after }
            if index
              base.insert(index + 1, entry)
              return
            end
          end

          if before
            index = base.index { |item| item[:label] == before }
            if index
              base.insert(index, entry)
              return
            end
          end

          # Default: append to end
          base << entry
        end
      end
    end
  end
end
