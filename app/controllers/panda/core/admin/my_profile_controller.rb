# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class MyProfileController < ::Panda::Core::AdminController
        before_action :set_initial_breadcrumb, only: %i[edit update]

        # Shows the edit form for the current user's profile
        # @type GET
        # @return void
        def edit
          render :edit, locals: {user: current_user}
        end

        # Updates the current user's profile
        # @type PATCH/PUT
        # @return void
        def update
          if current_user.update(user_params)
            flash[:success] = "Your profile has been updated successfully."
            redirect_to edit_admin_my_profile_path
          else
            render :edit, locals: {user: current_user}, status: :unprocessable_entity
          end
        end

        private

        def set_initial_breadcrumb
          add_breadcrumb "My Profile", edit_admin_my_profile_path
        end

        # Only allow a list of trusted parameters through
        # @type private
        # @return ActionController::StrongParameters
        def user_params
          # Base parameters that Core always allows
          base_params = [:firstname, :lastname, :email, :current_theme]

          # Allow additional params from configuration
          additional_params = Core.config.additional_user_params || []

          params.require(:user).permit(*(base_params + additional_params))
        end
      end
    end
  end
end
