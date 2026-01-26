# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class ContainerComponent < Panda::Core::Base
        renders_one :heading_slot, Panda::Core::Admin::HeadingComponent
        renders_one :tab_bar_slot, Panda::Core::Admin::TabBarComponent
        renders_one :body_slot
        renders_one :slideover_slot, Panda::Core::Admin::SlideoverComponent
        renders_one :footer_slot

        def initialize(full_height: false, **attrs)
          @full_height = full_height
          super(**attrs)
        end

        attr_reader :full_height

        private

        def section_classes
          base = "flex-auto"
          height = full_height ? "h-[calc(100vh-9rem)]" : nil
          [base, height].compact.join(" ")
        end
      end
    end
  end
end
