# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class UsersController < BaseController
        before_action :set_initial_breadcrumb
        before_action :set_user, only: %i[show edit update]

        # Lists all users
        # @type GET
        # @return void
        def index
          @users = User.order(:name)
        end

        # Shows a user's details
        # @type GET
        # @return void
        def show
          add_breadcrumb @user.name, admin_user_path(@user)
        end

        # Shows the edit form for a user
        # @type GET
        # @return void
        def edit
          add_breadcrumb @user.name, admin_user_path(@user)
          add_breadcrumb "Edit", edit_admin_user_path(@user)
        end

        # Updates a user
        # @type PATCH/PUT
        # @return void
        def update
          if @user.update(user_params)
            flash[:success] = "User has been updated successfully."
            redirect_to admin_users_path
          else
            add_breadcrumb @user.name, admin_user_path(@user)
            add_breadcrumb "Edit", edit_admin_user_path(@user)
            render :edit, status: :unprocessable_content
          end
        end

        private

        def set_initial_breadcrumb
          add_breadcrumb "Users", admin_users_path
        end

        def set_user
          @user = User.find(params[:id])
        end

        # Only allow a list of trusted parameters through
        # @type private
        # @return ActionController::StrongParameters
        def user_params
          params.require(:user).permit(:name, :email, :admin)
        end
      end
    end
  end
end
