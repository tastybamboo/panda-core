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
            # Render the dashboard view
            render :show
          end
        end
      end
    end
  end
end
