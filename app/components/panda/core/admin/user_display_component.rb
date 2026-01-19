# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class UserDisplayComponent < Panda::Core::Base
        def initialize(user_id:, user:, metadata: "", **attrs)
          @user_id = user_id
          @user = user
          @metadata = metadata
          super(**attrs)
        end

        attr_reader :user_id, :user, :metadata

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
            resolved_user.avatar_url(size: :small).present?

          if has_image
            content_tag(:div) do
              tag.img(
                class: "inline-block w-10 h-10 rounded-full object-cover",
                src: resolved_user.avatar_url(size: :small),
                alt: "",
                loading: "lazy"
              )
            end
          else
            content_tag(:div, class: "inline-block w-10 h-10 bg-gray-200 rounded-full flex items-center justify-center") do
              content_tag(:span, user_initials, class: "text-sm font-medium text-gray-600")
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
          content_tag(:div, class: "ml-3") do
            name_html = content_tag(:p, resolved_user.name, class: "text-sm text-black")
            meta_html = if @metadata.present?
              content_tag(:p, @metadata, class: "text-sm text-black/60")
            elsif resolved_user.respond_to?(:email) && resolved_user.email.present?
              content_tag(:p, resolved_user.email, class: "text-sm text-gray-500")
            else
              "".html_safe
            end
            (name_html + meta_html).html_safe
          end
        end
      end
    end
  end
end
