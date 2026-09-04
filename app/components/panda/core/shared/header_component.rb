# frozen_string_literal: true

module Panda
  module Core
    module Shared
      # Header component for HTML document head
      # Handles title, meta tags, stylesheets, and JavaScript
      class HeaderComponent < ViewComponent::Base
        def initialize(html_class: "", body_class: "", **attrs)
          super()
          @html_class = html_class
          @body_class = body_class
        end

        attr_reader :html_class, :body_class

        # Language for the <html lang> attribute.
        #
        # Screen readers use it to pick a pronunciation, so a page without one is
        # read in whatever the reader's default happens to be.
        def html_lang
          I18n.locale.to_s.presence || "en"
        end

        # Render Panda::Core.config.additional_head_content with a view context.
        #
        # Called with no receiver and no arguments, a host app's lambda has no
        # view and no request, so content_security_policy_nonce is nil inside it
        # and anything it injects (javascript_importmap_tags included) comes out
        # un-nonced and is dropped by a strict script-src.
        #
        # Two shapes are supported, so existing configuration keeps working:
        #
        #   # Arity 0 - evaluated against the view context, so view helpers and
        #   # content_security_policy_nonce resolve directly.
        #   config.additional_head_content = -> { javascript_importmap_tags(nonce: content_security_policy_nonce) }
        #
        #   # Arity 1 - the view context is yielded as an argument.
        #   config.additional_head_content = ->(view) { view.javascript_importmap_tags(nonce: view.content_security_policy_nonce) }
        def additional_head_content
          content = Panda::Core.config.additional_head_content
          return nil unless content.respond_to?(:call)

          result =
            if content.arity == 0
              helpers.instance_exec(&content)
            else
              content.call(helpers)
            end

          result&.to_s&.html_safe
        end
      end
    end
  end
end
