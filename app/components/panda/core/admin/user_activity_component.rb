# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class UserActivityComponent < Panda::Core::Base
        include ActionView::Helpers::DateHelper

        prop :model, _Nilable(Object), default: -> {}
        prop :at, _Nilable(Object), default: -> {}
        prop :user, _Nilable(Object), default: -> {}

        def view_template
          return unless should_render?

          if @user.is_a?(Panda::Core::User) && time
            render Panda::Core::Admin::UserDisplayComponent.new(
              user: @user,
              metadata: "#{time_ago_in_words(time)} ago"
            )
          elsif @user.is_a?(Panda::Core::User)
            render Panda::Core::Admin::UserDisplayComponent.new(
              user: @user,
              metadata: "Not published"
            )
          elsif time
            div(class: "text-black/60") { "#{time_ago_in_words(time)} ago" }
          end
        end

        private

        def time
          @at if @at.is_a?(ActiveSupport::TimeWithZone)
        end

        def should_render?
          @user.is_a?(Panda::Core::User) || time
        end
      end
    end
  end
end
