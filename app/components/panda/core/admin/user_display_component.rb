# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class UserDisplayComponent < Panda::Core::Base
        prop :user_id, _Nilable(String), default: -> {}
        prop :user, _Nilable(Object), default: -> {}
        prop :metadata, String, default: ""

        def view_template
          return unless resolved_user

          div(class: "block flex-shrink-0 group") do
            div(class: "flex items-center") do
              render_avatar
              render_user_info
            end
          end
        end

        private

        def resolved_user
          @resolved_user ||= if @user.nil? && @user_id.present?
            Panda::Core::User.find_by(id: @user_id)
          else
            @user
          end
        end

        def render_avatar
          has_image = resolved_user.respond_to?(:avatar_url) &&
            resolved_user.avatar_url.present?

          if has_image
            div do
              img(
                class: "inline-block w-10 h-10 rounded-full object-cover",
                src: resolved_user.avatar_url,
                alt: ""
              )
            end
          else
            div(class: "inline-block w-10 h-10 bg-gray-200 rounded-full flex items-center justify-center") do
              span(class: "text-sm font-medium text-gray-600") { user_initials }
            end
          end
        end

        def user_initials
          return "" unless resolved_user.respond_to?(:name)

          name_parts = resolved_user.name.to_s.split
          if name_parts.length >= 2
            "#{name_parts.first[0]}#{name_parts.last[0]}".upcase
          elsif name_parts.length == 1
            name_parts.first[0..1].upcase
          else
            ""
          end
        end

        def render_user_info
          div(class: "ml-3") do
            p(class: "text-sm text-black") { resolved_user.name }
            if @metadata.present?
              p(class: "text-sm text-black/60") { @metadata }
            elsif resolved_user.respond_to?(:email) && resolved_user.email.present?
              p(class: "text-sm text-gray-500") { resolved_user.email }
            end
          end
        end
      end
    end
  end
end
