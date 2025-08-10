# frozen_string_literal: true

module Panda
  module Core
    module Authentication
      extend ActiveSupport::Concern

      included do
        helper_method :current_user if respond_to?(:helper_method)
      end

      def current_user
        return @current_user if defined?(@current_user)
        @current_user = User.find_by(id: session[:user_id]) if session[:user_id]
      end

      def require_authentication
        redirect_to admin_login_path unless current_user
      end

      def require_admin
        redirect_to admin_login_path unless current_user&.is_admin?
      end

      def sign_in(user)
        session[:user_id] = user.id
        @current_user = user
      end

      def sign_out
        session.delete(:user_id)
        @current_user = nil
      end
    end
  end
end
