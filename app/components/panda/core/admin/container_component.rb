# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class ContainerComponent < Panda::Core::Base
        renders_one :heading, lambda { |text: "", icon: "", meta: nil, level: 2, **attrs, &block|
          Panda::Core::Admin::HeadingComponent.new(text: text, icon: icon, meta: meta, level: level, **attrs, &block)
        }
        renders_one :tab_bar, lambda { |tabs: [], **attrs|
          Panda::Core::Admin::TabBarComponent.new(tabs: tabs, **attrs)
        }
        renders_one :body
        renders_one :slideover, lambda { |title: "", **attrs, &block|
          Panda::Core::Admin::SlideoverComponent.new(title: title, **attrs, &block)
        }
        renders_one :footer

        def initialize(full_height: false, **attrs)
          @full_height = full_height
          super(**attrs)
        end

        attr_reader :full_height

        def before_render
          # Pass footer content to slideover if both exist
          if slideover? && footer?
            # Convert footer slot to HTML string before passing to slideover
            footer_html = footer.render_in(view_context)
            slideover.instance_variable_set(:@footer_html, footer_html)
          end
        end

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
