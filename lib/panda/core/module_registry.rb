# frozen_string_literal: true

module Panda
  module Core
    # Module registry for Panda ecosystem components
    #
    # This class maintains a registry of all Panda modules (CMS, CMS Pro, Community, etc.)
    # and their asset paths. Each module self-registers during engine initialization.
    #
    # Benefits:
    # - Core doesn't need hardcoded knowledge of other modules
    # - Supports private modules (e.g., panda-community in development)
    # - Single source of truth for asset compilation
    # - Scales automatically to future modules
    #
    # Usage:
    #   # In module's engine.rb (after class definition):
    #   Panda::Core::ModuleRegistry.register(
    #     gem_name: 'panda-cms',
    #     engine: 'Panda::CMS::Engine',
    #     paths: {
    #       views: 'app/views/panda/cms/**/*.erb',
    #       components: 'app/components/panda/cms/**/*.rb',
    #       stylesheets: 'app/assets/stylesheets/panda/cms/**/*.css'
    #     }
    #   )
    #
    class ModuleRegistry
      @modules = {}

      class << self
        # Register a Panda module with its asset paths
        #
        # @param gem_name [String] Gem name (e.g., 'panda-cms')
        # @param engine [String] Engine constant name (e.g., 'Panda::CMS::Engine')
        # @param paths [Hash] Asset path patterns relative to engine root
        # @option paths [String] :views View template paths
        # @option paths [String] :components ViewComponent paths
        # @option paths [String] :stylesheets Stylesheet paths (optional)
        def register(gem_name:, engine:, paths:)
          @modules[gem_name] = {
            engine: engine,
            paths: paths
          }
        end

        # Returns all registered modules
        #
        # @return [Hash] Module registry
        attr_reader :modules

        # Returns content paths for Tailwind CSS scanning
        #
        # Tailwind needs to scan all files that might contain utility classes:
        # - Views (ERB templates)
        # - Components (ViewComponent classes)
        # - JavaScript (Stimulus controllers, etc.)
        #
        # @return [Array<String>] Full paths for Tailwind --content flags
        def tailwind_content_paths
          paths = []

          # Core's own content (always included)
          core_root = Panda::Core::Engine.root
          paths << "#{core_root}/app/views/panda/core/**/*.erb"
          paths << "#{core_root}/app/components/panda/core/**/*.rb"

          # Registered modules (only if engine is loaded)
          @modules.each do |gem_name, info|
            next unless engine_available?(info[:engine])

            root = engine_root(info[:engine])
            next unless root

            # Add configured path types
            paths << "#{root}/#{info[:paths][:views]}" if info[:paths][:views]
            paths << "#{root}/#{info[:paths][:components]}" if info[:paths][:components]

            # For Tailwind scanning, we also need to scan JavaScript for utility classes
            # Check if module has JavaScript (via importmap or direct paths)
            js_root = root.join("app/javascript")
            if js_root.directory?
              paths << "#{js_root}/**/*.js"
            end
          end

          # Host application Panda overrides
          # Applications can override any Panda views/components
          if defined?(Rails.root)
            paths << "#{Rails.root}/app/views/panda/**/*.erb"
            paths << "#{Rails.root}/app/components/panda/**/*.rb"
            paths << "#{Rails.root}/app/javascript/panda/**/*.js"
          end

          paths.compact
        end

        # Returns JavaScript source files by introspecting importmaps
        #
        # Instead of duplicating file lists, we read the importmap configuration
        # that each engine already maintains. This provides a single source of truth.
        #
        # @return [Array<String>] Full paths to JavaScript source files
        def javascript_sources
          return [] unless defined?(Rails.application&.importmap)

          sources = []

          # Detect importmap-rails version and use appropriate API
          importmap = Rails.application.importmap
          entries = if importmap.respond_to?(:packages)
            # importmap-rails 2.x - packages is a hash
            importmap.packages
          elsif importmap.respond_to?(:entries)
            # importmap-rails 1.x - entries is an array
            importmap.entries.map { |e| [e.name, e] }.to_h
          else
            {}
          end

          # Find all Panda-namespaced imports and resolve to file paths
          entries.each do |name, config|
            next unless name.to_s.match?(/^panda-/)

            path = resolve_importmap_to_path(name, config)
            sources << path if path
          end

          sources.compact.uniq
        end

        # Returns registered module names
        #
        # @return [Array<String>] List of registered gem names
        def registered_modules
          @modules.keys
        end

        # Check if a specific module is registered
        #
        # @param gem_name [String] Gem name to check
        # @return [Boolean] True if module is registered
        def registered?(gem_name)
          @modules.key?(gem_name)
        end

        # Returns a combined importmap for all registered modules
        #
        # This merges importmaps from Core and all registered modules (CMS, CMS Pro, etc.)
        # into a single hash suitable for <script type="importmap"> generation.
        #
        # Order matters: Core imports are added first, then modules in registration order.
        # If there are conflicts, later modules override earlier ones.
        #
        # @return [Hash] Combined imports hash {"module/name" => "/path/to/file.js"}
        def combined_importmap
          imports = {}

          # Add Panda Core imports first (if Core has an importmap)
          if defined?(Panda::Core.importmap)
            Panda::Core.importmap.instance_variable_get(:@packages).each do |name, package|
              imports[name] = package.path
            end
          end

          # Add registered modules' importmaps in registration order
          @modules.each do |gem_name, info|
            next unless engine_available?(info[:engine])

            # Get the module's importmap constant (e.g., Panda::CMS.importmap)
            module_importmap = module_importmap_for(info[:engine])
            next unless module_importmap

            module_importmap.instance_variable_get(:@packages).each do |name, package|
              imports[name] = package.path
            end
          end

          imports
        end

        private

        # Get the importmap for a module
        #
        # @param engine_name [String] Engine constant name (e.g., "Panda::CMS::Engine")
        # @return [Importmap::Map, nil] Module's importmap or nil if not available
        def module_importmap_for(engine_name)
          # Extract module namespace from engine name (e.g., "Panda::CMS::Engine" -> "Panda::CMS")
          module_name = engine_name.sub(/::Engine$/, "")
          return nil unless Object.const_defined?(module_name)

          mod = Object.const_get(module_name)
          return nil unless mod.respond_to?(:importmap)

          mod.importmap
        rescue NoMethodError
          nil
        rescue NameError
          nil
        end

        # Check if an engine constant is defined and available
        #
        # @param engine_name [String] Engine constant name
        # @return [Boolean] True if engine is available
        def engine_available?(engine_name)
          Object.const_defined?(engine_name)
        rescue NameError
          false
        end

        # Get the root path of an engine
        #
        # @param engine_name [String] Engine constant name
        # @return [Pathname, nil] Engine root path or nil if unavailable
        def engine_root(engine_name)
          return nil unless engine_available?(engine_name)

          engine_class = Object.const_get(engine_name)
          engine_class.root
        rescue NoMethodError
          nil
        end

        # Resolve an importmap entry to an actual file path
        #
        # Importmap entries can be:
        # - Direct paths: "panda/cms/controllers/dashboard_controller.js"
        # - Module names: "panda-cms/controllers/dashboard_controller"
        #
        # We need to find where these files actually live in the filesystem.
        #
        # @param name [String, Symbol] Import name
        # @param config [Object] Importmap entry (structure varies by version)
        # @return [String, nil] Full file path or nil if not found
        def resolve_importmap_to_path(name, config)
          # Extract path from config (API differs between importmap-rails versions)
          relative_path = if config.respond_to?(:path)
            config.path
          elsif config.respond_to?(:[])
            config[:path] || config["path"]
          elsif config.is_a?(String)
            config
          end

          return nil unless relative_path

          # Try to find the file in registered engines
          @modules.each do |gem_name, info|
            next unless engine_available?(info[:engine])

            root = engine_root(info[:engine])
            next unless root

            # Check common JavaScript locations
            [
              root.join("app/javascript", relative_path),
              root.join("app/javascript", "#{relative_path}.js"),
              root.join("app/assets/javascripts", relative_path),
              root.join("app/assets/javascripts", "#{relative_path}.js")
            ].each do |candidate|
              return candidate.to_s if candidate.exist?
            end
          end

          # Check Rails app if available
          if defined?(Rails.root)
            [
              Rails.root.join("app/javascript", relative_path),
              Rails.root.join("app/javascript", "#{relative_path}.js")
            ].each do |candidate|
              return candidate.to_s if candidate.exist?
            end
          end

          nil
        end
      end
    end
  end
end
