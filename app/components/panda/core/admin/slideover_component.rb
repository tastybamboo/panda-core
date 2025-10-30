# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class SlideoverComponent < Panda::Core::Base
        prop :title, String, default: "Settings"

        def view_template(&block)
          # Set content_for equivalents that can be accessed by the layout
          helpers.content_for(:sidebar_title) { title }
          helpers.content_for(:sidebar) do
            aside(class: "hidden overflow-y-auto w-96 h-full bg-white lg:block", &block)
          end
        end
      end
    end
  end
end
