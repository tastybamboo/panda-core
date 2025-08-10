# frozen_string_literal: true

module Panda
  module Core
    class AdminController < ApplicationController
      # Automatically require admin authentication for all admin controllers
      before_action :authenticate_admin_user!
      before_action :set_initial_breadcrumb
      
      private
      
      def set_initial_breadcrumb
        # Use configured breadcrumb or default
        if Core.configuration.initial_admin_breadcrumb
          label, path = Core.configuration.initial_admin_breadcrumb.call(self)
          add_breadcrumb label, path
        else
          add_breadcrumb "Admin", admin_root_path
        end
      end
      
      # Legacy method for compatibility
      def set_admin_breadcrumb
        set_initial_breadcrumb
      end
    end
  end
end