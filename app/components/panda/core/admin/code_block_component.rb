# frozen_string_literal: true

module Panda
  module Core
    module Admin
      # Code block component for snippets and examples.
      class CodeBlockComponent < Panda::Core::Base
        def initialize(code: nil, **attrs)
          @code = code
          super(**attrs)
        end

        attr_reader :code

        def default_attrs
          {
            class: "rounded-xl bg-slate-900/95 p-3 text-xs text-emerald-200 font-mono overflow-x-auto"
          }
        end
      end
    end
  end
end
