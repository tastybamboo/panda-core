# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class SecretFieldComponent < Panda::Core::Base
        def initialize(value:, masked: true, **attrs)
          @value = value
          @masked = masked
          super(**attrs)
        end

        attr_reader :value, :masked

        def display_value
          if masked && value.present? && value.length > 4
            "\u2022" * 12 + value[-4..]
          else
            value
          end
        end

        def button_classes
          "shrink-0 btn btn-secondary transition"
        end
      end
    end
  end
end
