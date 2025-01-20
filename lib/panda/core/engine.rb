require "rubygems"

require "active_storage"
require "awesome_nested_set"
require "aws-sdk-s3"
require "dry-configurable"
require "faraday"
require "faraday/multipart"
require "faraday/retry"
require "image_processing"
require "importmap-rails"
require "lookbook"
require "omniauth"
require "omniauth/strategies/google_oauth2"
require "omniauth/strategies/github"
require "omniauth/strategies/microsoft_graph"
require "omniauth/rails_csrf_protection"
require "propshaft"
require "redis"
require "silencer"
require "stimulus-rails"
require "turbo-rails"
require "view_component"

require "rails/engine"

module Panda
  module Core
    class Engine < ::Rails::Engine
      isolate_namespace Panda::Core

      config.generators do |g|
        g.test_framework :rspec
        g.fixture_replacement :factory_bot
        g.factory_bot dir: "spec/factories"
      end

      initializer "panda_core.configuration" do |app|
        config.after_initialize do
          Panda::Core.configure do |config|
            config.parent_controller ||= "ActionController::API"
            config.parent_mailer ||= "ActionMailer::Base"
            config.mailer_sender ||= "support@example.com"
            config.mailer_default_url_options ||= {host: "localhost:3000"}
            config.session_token_cookie ||= :session_token
          end
        end
      end
    end
  end
end
