# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class FeatureFlagsController < BaseController
        before_action :set_initial_breadcrumb

        def index
          @feature_flags = FeatureFlag.order(:key)
          @grouped_flags = @feature_flags.group_by { |flag| flag.key.split(".").first }
        end

        def update
          @feature_flag = FeatureFlag.find(params[:id])
          FeatureFlag.toggle!(@feature_flag.key)

          new_state = @feature_flag.reload.enabled? ? "enabled" : "disabled"
          flash[:success] = "Feature flag \"#{@feature_flag.key}\" has been #{new_state}."
          redirect_to admin_feature_flags_path
        end

        private

        def set_initial_breadcrumb
          add_breadcrumb "Feature Flags", admin_feature_flags_path
        end
      end
    end
  end
end
