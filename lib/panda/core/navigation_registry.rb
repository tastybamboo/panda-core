# frozen_string_literal: true

module Panda
  module Core
    class NavigationRegistry
      # Collects items added via a section block
      class SectionContext
        attr_reader :items

        def initialize
          @items = []
        end

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
        # @param label [String] Section label
        # @param icon [String] FontAwesome icon class
        # @param after [String, nil] Insert after the section with this label
        # @param before [String, nil] Insert before the section with this label
        # @param visible [Proc, nil] Lambda receiving user, hides section when false
        # @param position [Symbol] :top (default) or :bottom — controls sidebar placement
        # @param block [Proc] Optional block yielding a SectionContext for adding items
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

        # Register an item to be added to a named section.
        # @param label [String] Item label
        # @param section [String] Target section label
        # @param path [String, nil] Path (auto-prefixed with admin_path)
        # @param url [String, nil] Full URL (used as-is)
        # @param target [String, nil] HTML target attribute
        # @param visible [Proc, nil] Lambda receiving user, hides item when false
        # @param before [Symbol, String, nil] :all to insert at beginning, or label to insert before
        # @param after [Symbol, String, nil] :all to insert at end (default), or label to insert after
        # @param method [Symbol, nil] HTTP method (e.g. :delete for logout buttons)
        # @param button_options [Hash] Extra options for button_to rendering
        # @param path_helper [Symbol, nil] Route helper name, resolved at build time via helpers
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

        # Build the final navigation array by combining the base lambda items
        # with registered sections and items.
        # @param user [Object] The current user
        # @param helpers [Object, nil] View helpers for resolving path_helper: symbols
        # @return [Array<Hash>] Navigation items
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

          # Migrate legacy admin_user_menu_items into the appropriate bottom section
          legacy_items = Panda::Core.config.admin_user_menu_items
          if legacy_items&.any?
            # Find an existing bottom section to append to, or create one
            bottom_section = base.find { |s| s[:position] == :bottom }
            if bottom_section
              legacy_items.each do |menu_item|
                next if menu_item[:path].blank? && menu_item[:url].blank?
                resolved = {label: menu_item[:label], path: menu_item[:path]}
                resolved[:_visible] = menu_item[:visible]
                # Insert before the last child (Logout) if it exists
                logout_idx = bottom_section[:children]&.index { |c| c[:label] == "Logout" }
                if logout_idx
                  bottom_section[:children].insert(logout_idx, resolved)
                else
                  (bottom_section[:children] ||= []) << resolved
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
            resolved[:path] = helpers.panda_core.send(item[:path_helper])
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
