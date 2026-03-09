# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class SearchBarComponent < Panda::Core::Base
        def initialize(**attrs)
          super(**attrs)
        end

        def render?
          Panda::Core::SearchRegistry.providers.any? { |p| p[:search_class].respond_to?(:admin_search) }
        end

        def search_url
          Panda::Core::Engine.routes.url_helpers.admin_search_path
        end

        def shortcut_hint
          mac? ? "\u2318K" : "Ctrl+K"
        end

        private

        def mac?
          true # Safe default for shortcut display; JS handles both
        end
      end
    end
  end
end
