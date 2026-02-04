# frozen_string_literal: true

module Panda
  module Core
    module FormHelper
      # Wraps form_with to apply consistent admin form styling across all Panda engines.
      # Sets the custom FormBuilder and applies default CSS classes for padding/layout.
      def panda_form_with(**options, &)
        options[:builder] = Panda::Core::FormBuilder
        options[:class] = ["block visible px-4 sm:px-6 pt-4", options[:class]].compact.join(" ")
        form_with(**options, &)
      end
    end
  end
end
