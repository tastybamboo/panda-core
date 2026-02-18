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
    # * +path_helper:+ — a route helper symbol resolved at build time via +helpers+
    # * +target:+ — HTML target attribute (e.g. <tt>"_blank"</tt>), omitted when +nil+
    #
    # == Visibility and filtering
    #
    # * +visible:+ — lambda receiving user, evaluated at build time; item/section
    #   hidden when false
    # * +filter()+ — post-build removal of items/sections by label, conditional
    #   on a user-receiving lambda
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
    #     # Permission-based visibility
    #     config.insert_admin_menu_item "Suggestions",
    #       section: "Tools",
    #       path: "cms/content_suggestions",
    #       visible: -> (user) { user.admin? || user.has_permission?(:review_content) }
    #
    #     # Post-build filter (hides for non-admins)
    #     config.filter_admin_menu "Roles",
    #       visible: -> (user) { user.admin? }
    #
    #     # Bottom section (rendered with UserMenuComponent)
    #     config.insert_admin_menu_section "Notifications",
    #       position: :bottom do |s|
    #         s.item "All", path: "notifications"
    #       end
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
    # 4. Legacy +admin_user_menu_items+ are migrated into the "My Account" bottom section
    # 5. Visibility lambdas are evaluated; items/sections hidden when +visible:+ returns false
    # 6. Post-build filters are applied
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
        # @param visible [Proc, nil] Lambda receiving user, hides item when false
        # @param method [Symbol, nil] HTTP method (e.g. :delete for logout buttons)
        # @param button_options [Hash] Extra options for button_to rendering
        # @param path_helper [Symbol, nil] Route helper name, resolved at build time via helpers
        # rubocop:disable Metrics/ParameterLists
        def item(label, path: nil, url: nil, target: nil, visible: nil,
          method: nil, button_options: {}, path_helper: nil)
          @items << {
            label: label, path: path, url: url, target: target,
            visible: visible, method: method, button_options: button_options,
            path_helper: path_helper
          }
        end
        # rubocop:enable Metrics/ParameterLists
      end

      @sections = []
      @items = []
      @filters = []

      class << self
        attr_reader :sections, :items, :filters

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
        # @param visible [Proc, nil] Lambda receiving user, hides section when false
        # @param position [Symbol] :top (default) or :bottom — controls sidebar placement
        # @yield [SectionContext] Optional block for adding items to the section
        #
        # @example Add a section with items after "Website"
        #   section("Members", icon: "fa-solid fa-users", after: "Website") do |s|
        #     s.item "Onboarding", path: "members/onboarding"
        #   end
        #
        # @example Add a permission-gated section
        #   section("Settings", icon: "fa-solid fa-gear",
        #     visible: -> (user) { user.admin? })
        #
        # @example Add a bottom section (rendered with UserMenuComponent)
        #   section("Notifications", position: :bottom) do |s|
        #     s.item "All", path: "notifications"
        #   end
        # rubocop:disable Metrics/ParameterLists
        def section(label, icon: nil, after: nil, before: nil, visible: nil, position: :top, &block)
          context = SectionContext.new
          yield context if block

          @sections << {
            label: label,
            icon: icon,
            after: after,
            before: before,
            visible: visible,
            position: position,
            items: context.items
          }
        end
        # rubocop:enable Metrics/ParameterLists

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
        # @param visible [Proc, nil] Lambda receiving user, hides item when false
        # @param before [Symbol, String, nil] :all to insert at beginning, or label to insert before
        # @param after [Symbol, String, nil] :all to insert at end (default), or label to insert after
        # @param method [Symbol, nil] HTTP method (e.g. :delete for logout buttons)
        # @param button_options [Hash] Extra options for button_to rendering
        # @param path_helper [Symbol, nil] Route helper name, resolved at build time via helpers
        #
        # @example Add to an existing section with auto-prefixed path
        #   item("Feature Flags", section: "Settings", path: "feature_flags")
        #
        # @example Add an external link
        #   item("Docs", section: "Help", url: "https://docs.example.com", target: "_blank")
        #
        # @example Permission-gated item positioned before "Roles"
        #   item("General", section: "Settings", path: "general",
        #     visible: -> (user) { user.admin? }, before: "Roles")
        # rubocop:disable Metrics/ParameterLists
        def item(label, section:, path: nil, url: nil, target: nil, visible: nil,
          before: nil, after: nil, method: nil, button_options: {}, path_helper: nil)
          @items << {
            label: label,
            section: section,
            path: path,
            url: url,
            target: target,
            visible: visible,
            before: before,
            after: after,
            method: method,
            button_options: button_options,
            path_helper: path_helper
          }
        end
        # rubocop:enable Metrics/ParameterLists

        # Register a post-build filter that conditionally hides items by label.
        # Walks all sections and their children during build().
        # @param label [String] Label to match
        # @param visible [Proc] Lambda receiving user — item hidden when false
        def filter(label, visible:)
          @filters << {label: label, visible: visible}
        end

        # Build the final navigation array for the current user.
        #
        # Called once per request by the sidebar component. Combines the base
        # +admin_navigation_items+ lambda with all registered sections, items,
        # and filters.
        #
        # @param user [Object] The current authenticated user
        # @param helpers [Object, nil] View helpers for resolving path_helper: symbols
        # @return [Array<Hash>] Navigation items ready for rendering
        def build(user, helpers: nil)
          base = Panda::Core.config.admin_navigation_items&.call(user) || []
          admin_path = Panda::Core.config.admin_path

          # Apply registered sections
          @sections.each do |section|
            # Skip if a section with this label already exists in base
            next if base.any? { |item| item[:label] == section[:label] }

            entry = {label: section[:label], icon: section[:icon], position: section[:position], _visible: section[:visible]}
            if section[:items].any?
              entry[:children] = section[:items].map { |item|
                resolved = resolve_item(item, admin_path, helpers)
                resolved[:_visible] = item[:visible]
                resolved
              }
            end

            insert_section(base, entry, after: section[:after], before: section[:before])
          end

          # Apply registered items to their target sections
          @items.each do |item|
            target_section = base.find { |s| s[:label] == item[:section] }
            next unless target_section

            target_section[:children] ||= []
            resolved = resolve_item(item, admin_path, helpers)
            resolved[:_visible] = item[:visible]

            insert_item(target_section[:children], resolved, before: item[:before], after: item[:after])
          end

          # Migrate legacy admin_user_menu_items into the "My Account" bottom section
          legacy_items = Panda::Core.config.admin_user_menu_items
          if legacy_items&.any?
            my_account = base.find { |s| s[:label] == "My Account" && s[:position] == :bottom }
            if my_account
              legacy_items.each do |menu_item|
                next if menu_item[:path].blank? && menu_item[:url].blank?
                resolved = {label: menu_item[:label], path: menu_item[:path]}
                resolved[:_visible] = menu_item[:visible]
                # Insert before Logout if it exists
                logout_idx = my_account[:children]&.index { |c| c[:label] == "Logout" }
                if logout_idx
                  my_account[:children].insert(logout_idx, resolved)
                else
                  (my_account[:children] ||= []) << resolved
                end
              end
            end
          end

          # Apply section-level visible: — remove sections hidden for this user
          base.reject! { |entry| entry[:_visible] && !entry[:_visible].call(user) }

          # Apply item-level visible: — remove children hidden for this user
          base.each do |entry|
            next unless entry[:children]
            entry[:children].reject! { |child| child[:_visible] && !child[:_visible].call(user) }
          end

          # Apply registered filters — walk all sections and children
          @filters.each do |filter|
            base.reject! { |entry| entry[:label] == filter[:label] && !filter[:visible].call(user) }
            base.each do |entry|
              next unless entry[:children]
              entry[:children].reject! { |child| child[:label] == filter[:label] && !filter[:visible].call(user) }
            end
          end

          # Clean up internal keys before returning
          base.each do |entry|
            entry.delete(:_visible)
            entry[:position] ||= :top
            entry[:children]&.each { |child| child.delete(:_visible) }
          end

          base
        end

        # Clear all registrations (for test isolation).
        def reset!
          @sections = []
          @items = []
          @filters = []
        end

        private

        # Resolve path:, url:, or path_helper: into a final :path value.
        # Includes :target, :method, :button_options when present.
        def resolve_item(item, admin_path, helpers = nil)
          resolved = {label: item[:label]}

          if item[:path_helper] && helpers
            resolved[:path] = helpers.panda_core.public_send(item[:path_helper])
          elsif item[:url]
            resolved[:path] = item[:url]
          elsif item[:path]
            resolved[:path] = "#{admin_path}/#{item[:path]}"
          elsif item[:path_helper]
            # Keep path_helper for template-level resolution when helpers unavailable
            resolved[:path_helper] = item[:path_helper]
          end

          resolved[:target] = item[:target] if item[:target]
          resolved[:method] = item[:method] if item[:method]
          resolved[:button_options] = item[:button_options] if item[:button_options]&.any?
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

        # Insert an item into a section's children at the correct position.
        def insert_item(children, entry, before: nil, after: nil)
          if before == :all
            children.insert(0, entry)
            return
          end

          if before.is_a?(String)
            index = children.index { |child| child[:label] == before }
            if index
              children.insert(index, entry)
              return
            end
          end

          if after.is_a?(String)
            index = children.index { |child| child[:label] == after }
            if index
              children.insert(index + 1, entry)
              return
            end
          end

          # Default (including after: :all): append to end
          children << entry
        end
      end
    end
  end
end
