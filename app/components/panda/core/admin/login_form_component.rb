# frozen_string_literal: true

module Panda
  module Core
    module Admin
      # Login form component for OAuth provider authentication
      # Displays configured authentication providers for user login
      class LoginFormComponent < Panda::Core::Base
        def initialize(providers: [], **attrs)
          @providers = providers
          super(**attrs)
        end

        attr_reader :providers

        private

        def default_attrs
          {
            class: "flex flex-col justify-center py-12 px-6 min-h-full text-center lg:px-8"
          }
        end
      end
    end
  end
end
