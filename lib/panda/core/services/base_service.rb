module Panda
  module Core
    module Services
      class BaseService
        # Simple result object for service responses
        class Result
          attr_reader :payload, :errors

          def initialize(success:, payload: {}, errors: nil)
            @success = success
            @payload = payload
            @errors = errors
          end

          def success?
            @success
          end
        end

        def self.call(**kwargs)
          new(**kwargs).call
        end

        private

        def success(payload = {})
          Result.new(success: true, payload: payload)
        end

        def failure(errors)
          Result.new(success: false, errors: errors)
        end
      end
    end
  end
end
