require "active_support/core_ext/numeric/bytes"

module Panda
  module Core
    class Configuration
      attr_accessor :user_class,
        :user_identity_class,
        :storage_provider,
        :cache_store,
        :parent_controller,
        :parent_mailer,
        :auto_mount_engine,
        :mailer_sender,
        :mailer_default_url_options,
        :session_token_cookie,
        :authentication_providers,
        :admin_path,
        :admin_navigation_items,
        :admin_dashboard_widgets,
        :user_attributes,
        :user_associations,
        :authorization_policy,
        :additional_user_params,
        :available_themes,
        :default_theme,
        :login_logo_path,
        :login_page_title,
        :admin_title,
        :initial_admin_breadcrumb,
        :dashboard_redirect_path,
        :avatar_variants,
        :avatar_max_file_size,
        :avatar_max_dimension,
        :avatar_optimization_quality,
        :avatar_image_processor,
        :admin_user_menu_items

      def initialize
        @user_class = "Panda::Core::User"
        @user_identity_class = "Panda::Core::UserIdentity"
        @storage_provider = :active_storage
        @cache_store = :memory_store
        @parent_controller = "ActionController::API"
        @parent_mailer = "ActionMailer::Base"
        @auto_mount_engine = true
        @mailer_sender = "support@example.com"
        @mailer_default_url_options = {host: "localhost:3000"}
        @session_token_cookie = :panda_session
        @authentication_providers = {}
        @admin_path = "/admin"
        @default_theme = "default"

        # Hook system for extending admin UI with sensible defaults
        @admin_navigation_items = ->(user) {
          items = [
            {
              label: "Dashboard",
              path: @admin_path,
              icon: "fa-solid fa-house"
            }
          ]

          # Add CMS navigation if available
          if defined?(Panda::CMS)
            items << {
              label: "Content",
              path: "#{@admin_path}/cms",
              icon: "fa-solid fa-file-lines"
            }
          end

          items << {
            label: "My Profile",
            path: "#{@admin_path}/my_profile/edit",
            icon: "fa-solid fa-user"
          }

          items << {
            label: "Settings",
            icon: "fa-solid fa-gear",
            children: [
              {label: "Feature Flags", path: "#{@admin_path}/feature_flags"}
            ]
          }

          items
        }
        @admin_dashboard_widgets = ->(user) { [] }
        @user_attributes = []
        @user_associations = []
        @authorization_policy = ->(user, action, resource) { user.admin? }

        # Profile and UI customization
        @additional_user_params = []
        @available_themes = [["Default", "default"], ["Sky", "sky"]]
        @login_logo_path = nil
        @login_page_title = "Panda Admin"
        @admin_title = "Panda Admin"
        @initial_admin_breadcrumb = nil  # Proc that returns [label, path]
        @dashboard_redirect_path = nil  # Path to redirect to after login (defaults to admin_root_path)

        # Avatar configuration
        @avatar_variants = {
          thumb: {resize_to_limit: [50, 50]},
          small: {resize_to_limit: [100, 100]},
          medium: {resize_to_limit: [200, 200]},
          large: {resize_to_limit: [400, 400]}
        }
        @avatar_max_file_size = 5.megabytes
        @avatar_max_dimension = 800
        @avatar_optimization_quality = 85
        @avatar_image_processor = :vips # or :mini_magick

        # Legacy extensible user menu items (prefer NavigationRegistry with position: :bottom)
        @admin_user_menu_items = []

        # Register default user menu as a bottom navigation section
        register_default_user_menu
      end

      # Register a new admin navigation section via NavigationRegistry.
      # @param label [String] Section label
      # @param icon [String] FontAwesome icon class
      # @param after [String, nil] Insert after the section with this label
      # @param before [String, nil] Insert before the section with this label
      # @param visible [Proc, nil] Lambda receiving user, hides section when false
      # @param position [Symbol] :top (default) or :bottom
      def insert_admin_menu_section(label, icon: nil, after: nil, before: nil, visible: nil, position: :top, &block)
        Panda::Core::NavigationRegistry.section(label, icon: icon, after: after, before: before, visible: visible, position: position, &block)
      end

      # Register an item to be added to an existing admin navigation section.
      # @param label [String] Item label
      # @param section [String] Target section label
      # @param path [String, nil] Path (auto-prefixed with admin_path)
      # @param url [String, nil] Full URL (used as-is)
      # @param target [String, nil] HTML target attribute
      # @param visible [Proc, nil] Lambda receiving user, hides item when false
      # @param before [Symbol, String, nil] :all or label — position within section
      # @param after [Symbol, String, nil] :all or label — position within section
      # @param method [Symbol, nil] HTTP method (e.g. :delete)
      # @param button_options [Hash] Extra options for button_to
      # @param path_helper [Symbol, nil] Route helper resolved at build time
      # rubocop:disable Metrics/ParameterLists
      def insert_admin_menu_item(label, section:, path: nil, url: nil, target: nil,
        visible: nil, before: nil, after: nil, method: nil, button_options: {}, path_helper: nil)
        Panda::Core::NavigationRegistry.item(
          label, section: section, path: path, url: url, target: target,
          visible: visible, before: before, after: after,
          method: method, button_options: button_options, path_helper: path_helper
        )
      end
      # rubocop:enable Metrics/ParameterLists

      # Convenience: add an item to the user menu (bottom section).
      # @param label [String] Item label
      # @param path [String, nil] Path (auto-prefixed with admin_path)
      # @param url [String, nil] Full URL (used as-is)
      # @param visible [Proc, nil] Lambda receiving user, hides item when false
      # @param position [Symbol] :before_logout (default) or :top
      def insert_admin_user_menu_item(label, path: nil, url: nil, visible: nil, position: :before_logout)
        before_opt = (position == :before_logout) ? "Logout" : nil
        before_opt = :all if position == :top
        Panda::Core::NavigationRegistry.item(
          label, section: "My Account", path: path, url: url,
          visible: visible, before: before_opt
        )
      end

      # Register a post-build filter that conditionally hides items by label.
      # @param label [String] Label to match
      # @param visible [Proc] Lambda receiving user — item hidden when false
      def filter_admin_menu(label, visible:)
        Panda::Core::NavigationRegistry.filter(label, visible: visible)
      end

      # Register a dashboard widget via WidgetRegistry.
      # @param label [String] Widget label
      # @param component [Proc] Lambda receiving user, returns a component instance
      # @param visible [Proc, nil] Lambda receiving user, hides widget when false
      # @param position [Integer] Sort order (lower first)
      def register_admin_dashboard_widget(label, component:, visible: nil, position: 0)
        Panda::Core::WidgetRegistry.register(label, component: component, visible: visible, position: position)
      end

      private

      # Register the default user menu items as a bottom navigation section.
      def register_default_user_menu
        Panda::Core::NavigationRegistry.section("My Account", position: :bottom) do |s|
          s.item "My Profile", path: "my_profile/edit"
          s.item "Login & Security", path: "my_profile/logins"
          s.item "Logout", path_helper: :admin_logout_path, method: :delete,
            button_options: {id: "logout-link", data: {turbo: false}}
        end
      end
    end

    class << self
      attr_writer :config

      def config
        @config ||= Configuration.new
      end

      def configure
        yield(config)
      end

      def reset_config!
        @config = Configuration.new
      end

      # Alias for backward compatibility with test expectations
      alias_method :reset_configuration!, :reset_config!
    end
  end
end
