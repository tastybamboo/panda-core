# frozen_string_literal: true

require_relative "preparer"
require_relative "verifier"
require_relative "report"

module Panda
  module Core
    module Testing
      module Assets
        class Runner
          Result = Struct.new(:prepare, :verify)

          def initialize(engine)
            @engine = engine
          end

          #
          # Full pipeline (prepare + verify + report)
          #
          def run
            prepare_result = Preparer.new(@engine).run
            verify_result = Verifier.new(@engine).run

            combined = Result.new(prepare_result, verify_result)

            Report.write(@engine, combined)

            if verification_failed?(verify_result)
              puts "\n❌ Asset verification FAILED for #{@engine}\n\n"
              exit 1
            else
              puts "\n✅ Asset verification OK for #{@engine}\n\n"
            end

            combined
          end

          #
          # Just preparation (no verification)
          #
          def prepare
            Preparer.new(@engine).run
          end

          #
          # Just verification (used in debugging)
          #
          def verify
            verify_result = Verifier.new(@engine).run

            if verification_failed?(verify_result)
              puts "\n❌ Asset verification FAILED for #{@engine}\n\n"
              exit 1
            else
              puts "\n✅ Asset verification OK for #{@engine}\n\n"
            end

            verify_result
          end

          private

          #
          # Decide whether verification had ANY failures
          #
          def verification_failed?(verify_result)
            verify_result.any? do |_stage, data|
              data[:status] == :failed
            end
          end
        end
      end
    end
  end
end
