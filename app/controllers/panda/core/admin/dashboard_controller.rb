# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class DashboardController < AdminController
        # Authentication is automatically enforced by AdminController

        def show
          # If a custom dashboard path is configured, redirect there
          if Panda::Core.configuration.dashboard_redirect_path
            redirect_to Panda::Core.configuration.dashboard_redirect_path
          else
            # This can be overridden by applications using panda-core
            # For now, just render a basic view
            render plain: "Welcome to Panda Admin"
          end
        end
      end
    end
  end
end
