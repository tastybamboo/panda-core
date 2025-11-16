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

      # Custom Rack middleware to serve JavaScript modules from all registered Panda modules
      #
      # This middleware checks all registered modules' app/javascript/panda directories
      # and serves the first matching file. This solves the problem of multiple Rack::Static
      # instances blocking each other.
      #
      class JavaScriptMiddleware
        def initialize(app)
          @app = app
        end

        def call(env)
          request = Rack::Request.new(env)
          path = request.path_info

          # Only handle /panda/core/* and /panda/cms/* style JavaScript module requests
          # Skip paths like /panda-core-assets/* (public assets handled by Rack::Static)
          return @app.call(env) unless path.start_with?("/panda/")

          # Strip /panda/ prefix to get relative path
          # e.g., "/panda/cms/application.js" -> "cms/application.js"
          relative_path = path.sub(%r{^/panda/}, "")
          return @app.call(env) if relative_path.empty?

          # Try to find the file in registered modules
          if ENV["RSPEC_DEBUG"]
            puts "[JavaScriptMiddleware] Looking for: #{path} (relative: #{relative_path})"
          end

          file_path = find_javascript_file(relative_path)

          if file_path && File.file?(file_path)
            puts "[JavaScriptMiddleware] ✅ Serving: #{path} from #{file_path}" if ENV["RSPEC_DEBUG"]
            serve_file(file_path, env)
          else
            if ENV["RSPEC_DEBUG"]
              puts "[JavaScriptMiddleware] ❌ Not found: #{path}"
              puts "[JavaScriptMiddleware]    Searched relative path: #{relative_path}"
              puts "[JavaScriptMiddleware]    Checked locations:"
              ModuleRegistry.modules.each do |gem_name, info|
                if ModuleRegistry.send(:engine_available?, info[:engine])
                  root = ModuleRegistry.send(:engine_root, info[:engine])
                  if root
                    puts "[JavaScriptMiddleware]      - #{root.join("app/javascript/panda", relative_path)}"
                    puts "[JavaScriptMiddleware]      - #{root.join("public/panda", relative_path)}"
                  end
                end
              end
              if defined?(Rails.root)
                puts "[JavaScriptMiddleware]      - #{Rails.root.join("app/javascript/panda", relative_path)}"
                puts "[JavaScriptMiddleware]      - #{Rails.root.join("public/panda", relative_path)}"
              end
            end
            @app.call(env)
          end
        rescue => e
          # On error, log and pass to next middleware
          puts "[JavaScriptMiddleware] Error: #{e.message}" if ENV["RSPEC_DEBUG"]
          Rails.logger.error("[ModuleRegistry::JavaScriptMiddleware] Error: #{e.message}\n#{e.backtrace.join("\n")}") if defined?(Rails.logger)
          @app.call(env)
        end

        private

        def find_javascript_file(relative_path)
          # Check each registered module's JavaScript directory
          ModuleRegistry.modules.each do |gem_name, info|
            next unless ModuleRegistry.send(:engine_available?, info[:engine])

            root = ModuleRegistry.send(:engine_root, info[:engine])
            next unless root

            # Check in app/javascript/panda/ (primary location)
            candidate = root.join("app/javascript/panda", relative_path)
            return candidate.to_s if candidate.exist? && candidate.file?

            # Fallback to public/panda/ (for CI environments where assets are copied)
            public_candidate = root.join("public/panda", relative_path)
            return public_candidate.to_s if public_candidate.exist? && public_candidate.file?
          end

          # Also check Rails.root if available (for dummy apps in CI)
          if defined?(Rails.root)
            # Check app/javascript/panda/ in Rails.root
            rails_candidate = Rails.root.join("app/javascript/panda", relative_path)
            return rails_candidate.to_s if rails_candidate.exist? && rails_candidate.file?

            # Fallback to public/panda/ in Rails.root
            rails_public_candidate = Rails.root.join("public/panda", relative_path)
            return rails_public_candidate.to_s if rails_public_candidate.exist? && rails_public_candidate.file?
          end

          nil
        end

        def serve_file(file_path, env)
          # Read file content
          content = File.read(file_path)

          # Determine content type
          content_type = case File.extname(file_path)
          when ".js"
            "application/javascript; charset=utf-8"
          when ".json"
            "application/json; charset=utf-8"
          else
            "text/plain; charset=utf-8"
          end

          # Determine cache control
          cache_control = if Rails.env.development? || Rails.env.test?
            "no-cache, no-store, must-revalidate"
          else
            "public, max-age=31536000"
          end

          # Return response
          [
            200,
            {
              "Content-Type" => content_type,
              "Content-Length" => content.bytesize.to_s,
              "Cache-Control" => cache_control
            },
            [content]
          ]
        end
      end
    end
  end
end
