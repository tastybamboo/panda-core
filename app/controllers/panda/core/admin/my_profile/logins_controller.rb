# frozen_string_literal: true

module Panda
  module Core
    module Admin
      module MyProfile
        class LoginsController < BaseController
          before_action :set_initial_breadcrumb

          def show
            render :show, locals: {user: current_user}
          end

          private

          def set_initial_breadcrumb
            add_breadcrumb "My Profile", edit_admin_my_profile_path
            add_breadcrumb "Login & Security", admin_my_profile_logins_path
          end
        end
      end
    end
  end
end
