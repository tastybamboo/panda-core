# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class UserActivityComponent < Panda::Core::Base
        def initialize(model: nil, at: nil, user: nil, **attrs)
          @model = model
          @at = at
          @user = user
          super(**attrs)
        end

        attr_reader :model, :at, :user

        include ActionView::Helpers::DateHelper

        private

        def time
          @at if @at.is_a?(ActiveSupport::TimeWithZone)
        end

        def should_render?
          @user.present? || time
        end
      end
    end
  end
end
