# frozen_string_literal: true

module Panda
  module Core
    class ApplicationController < ActionController::Base
      protect_from_forgery with: :exception

      before_action :set_current_request_details
      before_action :initialize_breadcrumbs

      helper_method :current_user, :user_signed_in?, :breadcrumbs

      add_flash_types :success, :error, :warning, :info

      private

      def set_current_request_details
        Current.request_id = request.uuid
        Current.user_agent = request.user_agent
        Current.ip_address = request.ip
        Current.root = "#{request.protocol}#{request.host_with_port}"
        Current.user = User.find_by(id: session[:user_id]) if session[:user_id]
      end

      def authenticate_user!
        redirect_to admin_login_path unless user_signed_in?
      end

      def authenticate_admin_user!
        if !user_signed_in?
          redirect_to admin_login_path
        elsif !current_user.admin?
          redirect_to admin_login_path, flash: {error: "You are not authorized to access this page."}
        end
      end

      def current_user
        Current.user
      end

      def user_signed_in?
        current_user.present?
      end

      def initialize_breadcrumbs
        @breadcrumbs = []
      end

      def add_breadcrumb(label, path = nil)
        @breadcrumbs ||= []
        @breadcrumbs << Breadcrumb.new(label, path)
      end
      
      def breadcrumbs
        @breadcrumbs || []
      end
    end
  end
end
