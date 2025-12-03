# frozen_string_literal: true

module Panda
  module Core
    class Engine < ::Rails::Engine
      # Automatically mount the engine into host applications
      module RouteConfig
        extend ActiveSupport::Concern

        included do
          # Append Core routes to the host app after initialization so
          # engine routes are available without manual mounting.
          config.after_initialize do |app|
            next unless Panda::Core.config.auto_mount_engine

            already_mounted =
              app.routes.routes.any? do |route|
                route.app == Panda::Core::Engine ||
                  (route.app.respond_to?(:app) && route.app.app == Panda::Core::Engine)
              end
            already_mounted ||= app.routes.named_routes.key?(:panda_core)

            next if already_mounted

            app.routes.append do
              mount Panda::Core::Engine => "/", as: "panda_core"
            end
          end
        end
      end
    end
  end
end
