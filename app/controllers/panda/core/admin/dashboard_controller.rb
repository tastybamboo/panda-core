# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class DashboardController < BaseController
        # Authentication is automatically enforced by AdminController

        def show
          # If a custom dashboard path is configured, redirect there
          if Panda::Core.config.dashboard_redirect_path
            redirect_to Panda::Core.config.dashboard_redirect_path
          else
            # Render the dashboard view
            render :show
          end
        end
      end
    end
  end
end
