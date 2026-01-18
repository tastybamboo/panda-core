# frozen_string_literal: true

module Panda
  module Core
    module Admin
      # Default dashboard content component
      # Displays welcome message and quick action cards
      class DashboardDefaultContentComponent < Panda::Core::Base
        def initialize(user:, **attrs)
          @user = user
          super(**attrs)
        end

        attr_reader :user

        private

        def default_attrs
          { class: "mt-5" }
        end

        def dashboard_cards
          @dashboard_cards ||= if Panda::Core.config.respond_to?(:admin_dashboard_cards)
            Panda::Core.config.admin_dashboard_cards&.call(@user) || []
          else
            []
          end
        end
      end
    end
  end
end
