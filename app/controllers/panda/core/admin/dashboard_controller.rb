# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class DashboardController < AdminController
        # Authentication is automatically enforced by AdminController

        def index
          render plain: "Welcome to Panda Admin"
        end
      end
    end
  end
end
