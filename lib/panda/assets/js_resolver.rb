# frozen_string_literal: true

require "pathname"

module Panda
  module Assets
    module Testing
      # Resolves JS files for an engine across app/javascript and vendor/javascript
      # and handles conflicts by precedence.
      class JsResolver
        Entry = Struct.new(
          :logical,    # e.g. "application.js" or "controllers/menu_controller.js"
          :path,       # full Pathname on disk
          :source,     # :app or :vendor
          :engine_key, # :core / :cms / etc.
          keyword_init: true
        )

        attr_reader :engine_key, :engine_root

        def initialize(engine_key:, engine_root:)
          @engine_key = engine_key.to_sym
          @engine_root = Pathname(engine_root)
        end

        def resolved_entries
          grouped.values.map(&:first)
        end

        def all_entries
          grouped.values.flatten
        end

        private

        def grouped
          @grouped ||= begin
            entries = scan_root(app_js_root, source: :app) +
              scan_root(vendor_js_root, source: :vendor)

            entries.group_by(&:logical).transform_values do |group|
              # Precedence: app/javascript wins over vendor/javascript
              group.sort_by { |e| (e.source == :app) ? 0 : 1 }
            end
          end
        end

        def app_js_root
          engine_root.join("app/javascript/panda", engine_key.to_s)
        end

        def vendor_js_root
          engine_root.join("vendor/javascript/panda", engine_key.to_s)
        end

        def scan_root(root, source:)
          return [] unless root.directory?

          Dir[root.join("**/*.js")].map do |full|
            relative = Pathname(full).relative_path_from(root).to_s
            Entry.new(
              logical: relative,
              path: Pathname(full),
              source: source,
              engine_key: engine_key
            )
          end
        end
      end
    end
  end
end
