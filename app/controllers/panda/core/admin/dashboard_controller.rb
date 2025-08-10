# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class DashboardController < AdminController
        # Authentication is automatically enforced by AdminController

        def show
          # This can be overridden by applications using panda-core
          # For now, just render a basic view or redirect
          render plain: "Welcome to Panda Admin"
        end
      end
    end
  end
end
