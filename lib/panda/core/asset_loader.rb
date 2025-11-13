# frozen_string_literal: true

require "net/http"
require "fileutils"
require "json"

module Panda
  module Core
    # AssetLoader handles loading compiled assets from GitHub releases
    # Falls back to local development assets when GitHub assets unavailable
    class AssetLoader
      class << self
        # Generate HTML tags for loading Panda Core assets
        def asset_tags(options = {})
          if use_github_assets?
            github_asset_tags(options)
          else
            development_asset_tags(options)
          end
        end

        # Get the JavaScript asset URL
        def javascript_url
          if use_github_assets?
            github_javascript_url
          else
            development_javascript_url
          end
        end

        # Get the CSS asset URL (if exists)
        def css_url
          if use_github_assets?
            github_css_url
          else
            development_css_url
          end
        end

        # Check if GitHub-hosted assets should be used
        def use_github_assets?
          # In test, never use GitHub assets (use local engine assets instead)
          # This allows system tests to load CSS/JS from the engine's public directory
          return false if Rails.env.test? || in_test_environment?

          # Use GitHub assets in production or when explicitly enabled
          Rails.env.production? ||
            ENV["PANDA_CORE_USE_GITHUB_ASSETS"] == "true" ||
            !development_assets_available?
        end

        private

        def github_asset_tags(_options = {})
          version = asset_version
          base_url = github_base_url(version)

          tags = []

          # JavaScript tag with integrity check
          js_url = "#{base_url}panda-core-#{version}.js"

          js_attrs = {
            src: js_url
          }
          # In CI environment, don't use defer to ensure immediate execution
          js_attrs[:defer] = true unless ENV["GITHUB_ACTIONS"] == "true"

          tags << content_tag(:script, "", js_attrs)

          # CSS tag if CSS bundle exists
          css_url = "#{base_url}panda-core-#{version}.css"
          if github_asset_exists?(version, "panda-core-#{version}.css")
            css_attrs = {
              rel: "stylesheet",
              href: css_url
            }
            tags << tag(:link, css_attrs)
          end

          tags.join("\n").html_safe
        end

        def development_asset_tags(_options = {})
          # In test environment with CI, always use compiled assets
          if (Rails.env.test? || ENV["CI"].present?) && compiled_assets_available?
            # Use the same logic as GitHub assets but with local paths
            version = asset_version
            js_url = "/panda-core-assets/panda-core-#{version}.js"
            css_url = "/panda-core-assets/panda-core-#{version}.css"

            tags = []

            # JavaScript tag
            js_attrs = {
              src: js_url
            }
            js_attrs[:defer] = true unless ENV["GITHUB_ACTIONS"] == "true"
            tags << content_tag(:script, "", js_attrs)

            # CSS tag if exists
            if File.exist?(Rails.root.join("public", "panda-core-assets", "panda-core-#{version}.css"))
              css_attrs = {
                rel: "stylesheet",
                href: css_url
              }
              tags << tag(:link, css_attrs)
            end

          else
            # Development mode - use importmap for JS and static CSS
            tags = []
            tags << javascript_include_tag("panda/core/application", type: "module")

            # Add CSS if available
            css_path = development_css_url
            if css_path
              css_attrs = {
                rel: "stylesheet",
                href: css_path
              }
              tags << tag(:link, css_attrs)
            end
          end
          tags.join("\n").html_safe
        end

        def github_javascript_url
          version = asset_version
          # In test environment with local compiled assets, use local URL
          if Rails.env.test? && compiled_assets_available?
            "/panda-core-assets/panda-core-#{version}.js"
          else
            "#{github_base_url(version)}panda-core-#{version}.js"
          end
        end

        def github_css_url
          version = asset_version
          # In test environment with local compiled assets, use local URL
          if Rails.env.test? && compiled_assets_available?
            css_file = "/panda-core-assets/panda-core-#{version}.css"
            File.exist?(Rails.root.join("public#{css_file}")) ? css_file : nil
          else
            "#{github_base_url(version)}panda-core-#{version}.css"
          end
        end

        def development_javascript_url
          if compiled_assets_available?
            version = asset_version
            "/panda-core-assets/panda-core-#{version}.js"
          else
            # Return path for development/test mode
            # JavaScript is served via importmap, but static files are at this location
            "/panda-core-assets/js/application.js"
          end
        end

        def development_css_url
          assets_dir = Panda::Core::Engine.root.join("public", "panda-core-assets")

          # In dev/test, look for timestamp-based files (latest one)
          if Rails.env.test? || Rails.env.development?
            # Find all timestamp-based CSS files (exclude symlinks)
            css_files = Dir[assets_dir.join("panda-core-*.css")].reject { |f| File.symlink?(f) }

            if css_files.any?
              # Return the most recently created file
              latest = css_files.max_by { |f| File.basename(f)[/\d+/].to_i }
              return "/panda-core-assets/#{File.basename(latest)}"
            end
          else
            # In production, try versioned file first
            version = asset_version
            versioned_file = "/panda-core-assets/panda-core-#{version}.css"
            return versioned_file if File.exist?(Rails.public_path.join("panda-core-assets", "panda-core-#{version}.css"))
          end

          # Fall back to unversioned file (always available from engine's public directory)
          unversioned_file = "/panda-core-assets/panda-core.css"
          return unversioned_file if File.exist?(assets_dir.join("panda-core.css"))

          nil
        end

        def asset_version
          Panda::Core::VERSION
        end

        def github_base_url(version)
          "https://github.com/tastybamboo/panda-core/releases/download/v#{version}/"
        end

        def github_asset_exists?(_version, _filename)
          # For now, assume assets exist if we're using GitHub mode
          # Could implement actual checking via GitHub API
          true
        end

        def development_assets_available?
          # Check if we're in a development environment with importmap available
          Rails.env.development? && defined?(Importmap)
        end

        def compiled_assets_available?
          # Check if compiled assets exist in test location
          version = asset_version
          js_file = Rails.public_path.join("panda-core-assets", "panda-core-#{version}.js")
          js_file.exist?
        end

        def in_test_environment?
          # Additional check for test environment indicators
          ENV["CI"].present? || ENV["GITHUB_ACTIONS"].present? || ENV["RAILS_ENV"] == "test"
        end

        # Helper methods to match ActionView helpers
        def content_tag(name, content = nil, options = {})
          attrs = options.map do |k, v|
            if v == true
              k.to_s
            elsif v
              "#{k}=\"#{v}\""
            end
          end.compact.join(" ")

          if content || block_given?
            "<#{name}#{" #{attrs}" if attrs.present?}>#{content || (block_given? ? yield : "")}</#{name}>"
          else
            "<#{name}#{" #{attrs}" if attrs.present?}><#{name}>"
          end
        end

        def tag(name, options = {})
          attrs = options.map do |k, v|
            if v == true
              k.to_s
            elsif v
              "#{k}=\"#{v}\""
            end
          end.compact.join(" ")

          "<#{name}#{" #{attrs}" if attrs.present?} />"
        end

        def javascript_include_tag(source, options = {})
          options[:src] = source.start_with?("/") ? source : "/assets/#{source}"
          content_tag(:script, "", options)
        end
      end
    end
  end
end
