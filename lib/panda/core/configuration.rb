module Panda
  module Core
    class Configuration
      attr_accessor :user_class,
        :user_identity_class,
        :storage_provider,
        :cache_store,
        :parent_controller,
        :parent_mailer,
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
        :dashboard_redirect_path

      def initialize
        @user_class = "Panda::Core::User"
        @user_identity_class = "Panda::Core::UserIdentity"
        @storage_provider = :active_storage
        @cache_store = :memory_store
        @parent_controller = "ActionController::API"
        @parent_mailer = "ActionMailer::Base"
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
              icon: "fa-regular fa-house"
            }
          ]

          # Add CMS navigation if available
          if defined?(Panda::CMS)
            items << {
              label: "Content",
              path: "#{@admin_path}/cms",
              icon: "fa-regular fa-file-lines"
            }
          end

          items << {
            label: "My Profile",
            path: "#{@admin_path}/my_profile/edit",
            icon: "fa-regular fa-user"
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
    end
  end
end
