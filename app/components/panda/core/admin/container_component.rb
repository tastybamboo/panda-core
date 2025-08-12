# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class ContainerComponent < ViewComponent::Base
        renders_one :heading, "Panda::Core::Admin::HeadingComponent"
        renders_one :tab_bar, "Panda::Core::Admin::TabBarComponent"
        renders_one :slideover, "Panda::Core::Admin::SlideoverComponent"
      end
    end
  end
end
