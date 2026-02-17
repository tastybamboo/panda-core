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

        def item(label, path: nil, url: nil, target: nil)
          @items << {label: label, path: path, url: url, target: target}
        end
      end

      @sections = []
      @items = []

      class << self
        attr_reader :sections, :items

        # Register a new navigation section.
        # @param label [String] Section label
        # @param icon [String] FontAwesome icon class
        # @param after [String, nil] Insert after the section with this label
        # @param before [String, nil] Insert before the section with this label
        # @param block [Proc] Optional block yielding a SectionContext for adding items
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

        # Register an item to be added to a named section.
        # @param label [String] Item label
        # @param section [String] Target section label
        # @param path [String, nil] Path (auto-prefixed with admin_path)
        # @param url [String, nil] Full URL (used as-is)
        # @param target [String, nil] HTML target attribute
        def item(label, section:, path: nil, url: nil, target: nil)
          @items << {label: label, section: section, path: path, url: url, target: target}
        end

        # Build the final navigation array by combining the base lambda items
        # with registered sections and items.
        # @param user [Object] The current user
        # @return [Array<Hash>] Navigation items
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
