# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class UsersController < BaseController
        before_action :set_initial_breadcrumb
        before_action :set_user, only: %i[show edit update enable disable activity sessions revoke_session]

        def index
          @users = User.with_attached_avatar
          @users = @users.search(params[:search]) if params[:search].present?

          case params[:status]
          when "enabled" then @users = @users.enabled
          when "disabled" then @users = @users.disabled
          when "invited" then @users = @users.invited
          end

          case params[:role]
          when "admin" then @users = @users.admins
          when "user" then @users = @users.where(User.admin_column => false)
          end

          case params[:sort]
          when "name" then @users = @users.order(name: sort_direction)
          when "email" then @users = @users.order(email: sort_direction)
          when "last_login" then @users = @users.order(last_login_at: sort_direction)
          when "created" then @users = @users.order(created_at: sort_direction)
          else @users = @users.order(name: :asc)
          end

          @page = [params.fetch(:page, 1).to_i, 1].max
          @per_page = 25
          @total_count = @users.count
          @total_pages = (@total_count.to_f / @per_page).ceil
          @users = @users.offset((@page - 1) * @per_page).limit(@per_page)
        end

        def show
          add_breadcrumb @user.name, admin_user_path(@user)
          @recent_activity = @user.user_activities.recent.limit(5)
          @active_sessions = @user.user_sessions.active_sessions.recent
          @active_sessions_count = @active_sessions.size
        end

        def edit
          add_breadcrumb @user.name, admin_user_path(@user)
          add_breadcrumb "Edit", edit_admin_user_path(@user)
        end

        def update
          if @user.update(user_params)
            UserActivity.log!(user: current_user, action: "updated_user", resource: @user, request: request)
            flash[:success] = "User has been updated successfully."
            redirect_to admin_users_path
          else
            add_breadcrumb @user.name, admin_user_path(@user)
            add_breadcrumb "Edit", edit_admin_user_path(@user)
            render :edit, status: :unprocessable_content
          end
        end

        def invite
          result = InviteUserService.call(
            email: params[:email],
            name: params[:name],
            invited_by: current_user,
            admin: params[:admin] == "true"
          )

          if result.success?
            flash[:success] = "Invitation sent to #{params[:email]}."
          else
            flash[:error] = result.errors.join(", ")
          end
          redirect_to admin_users_path
        end

        def enable
          @user.enable!
          UserActivity.log!(user: current_user, action: "enabled_user", resource: @user, request: request)
          flash[:success] = "#{@user.name} has been enabled."
          redirect_to admin_user_path(@user)
        end

        def disable
          if @user == current_user
            flash[:error] = "You cannot disable your own account."
            redirect_to admin_user_path(@user)
            return
          end

          @user.disable!
          UserActivity.log!(user: current_user, action: "disabled_user", resource: @user, request: request)
          flash[:success] = "#{@user.name} has been disabled."
          redirect_to admin_user_path(@user)
        end

        def bulk_action
          user_ids = Array(params[:user_ids]).map(&:to_s)
          user_ids = user_ids.select { |id| id.match?(/\A[0-9a-f-]{36}\z/i) }

          return redirect_to admin_users_path, alert: "No valid users selected." if user_ids.blank?

          case params[:bulk_action]
          when "enable"
            enabled_count = User.where(id: user_ids).update_all(enabled: true)
            flash[:success] = "#{enabled_count} user(s) enabled."
          when "disable"
            disabled_count = User.where(id: user_ids).where.not(id: current_user.id).update_all(enabled: false)
            flash[:success] = "#{disabled_count} user(s) disabled (excluding yourself)."
          else
            flash[:error] = "Unknown action."
          end
          redirect_to admin_users_path
        end

        def activity
          add_breadcrumb @user.name, admin_user_path(@user)
          add_breadcrumb "Activity", activity_admin_user_path(@user)
          @activities = @user.user_activities.recent
          @page = [params.fetch(:page, 1).to_i, 1].max
          @per_page = 25
          @total_count = Rails.cache.fetch(["user_activities_count", @user.id], expires_in: 5.minutes) do
            @activities.count
          end
          @total_pages = (@total_count.to_f / @per_page).ceil
          @activities = @activities.offset((@page - 1) * @per_page).limit(@per_page)
        end

        def sessions
          add_breadcrumb @user.name, admin_user_path(@user)
          add_breadcrumb "Sessions", sessions_admin_user_path(@user)
          @sessions = @user.user_sessions.recent
          @page = [params.fetch(:page, 1).to_i, 1].max
          @per_page = 25
          @total_count = @sessions.count
          @total_pages = (@total_count.to_f / @per_page).ceil
          @sessions = @sessions.offset((@page - 1) * @per_page).limit(@per_page)
          @active_sessions = @user.user_sessions.active_sessions.recent
          @revoked_sessions = @user.user_sessions.revoked_sessions.recent
        end

        def revoke_session
          session_record = @user.user_sessions.find(params[:session_id])
          session_record.revoke!(admin: current_user)
          UserActivity.log!(
            user: current_user, action: "revoked_session", resource: @user,
            request: request, metadata: {session_id: session_record.id}
          )
          flash[:success] = "Session revoked."
          redirect_back fallback_location: admin_user_path(@user)
        end

        private

        def set_initial_breadcrumb
          add_breadcrumb "Users", admin_users_path
        end

        def set_user
          @user = User.find(params[:id])
        end

        def user_params
          params.require(:user).permit(:name, :email, :admin)
        end

        def sort_direction
          %w[asc desc].include?(params[:direction]) ? params[:direction].to_sym : :asc
        end
      end
    end
  end
end
