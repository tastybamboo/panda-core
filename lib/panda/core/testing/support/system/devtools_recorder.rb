# frozen_string_literal: true

require "ferrum"

module Panda
  module Core
    module Testing
      module Support
        module System
          # DevTools Recorder
          #
          # Patches Ferrum::Client to record DevTools commands for debugging purposes.
          # This can be useful when troubleshooting browser communication issues.
          module DevtoolsRecorder
            def command(method, params: nil, **kwargs)
              super
            end
          end
        end
      end
    end
  end
end

# Apply the patch to Ferrum::Client
Ferrum::Client.prepend(Panda::Core::Testing::Support::System::DevtoolsRecorder)
