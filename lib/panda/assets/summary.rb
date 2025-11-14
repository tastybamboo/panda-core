# frozen_string_literal: true

module Panda
  module Assets
    #
    # Summary is a structured record of everything that happened during the
    # Prepare + Verify pipeline. Runner fills this as it executes.
    #
    class Summary
      # Per-engine result record
      EngineResult = Struct.new(
        :engine,
        :prepare_ok,
        :verify_ok,
        :prepare_details,
        :verify_details,
        :timings,
        keyword_init: true
      )

      attr_reader :engine_results

      def initialize
        @engine_results = []
      end

      #
      # Add one result for a particular engine
      #
      def add_engine_result(engine:, prepare_ok:, verify_ok:, prepare_details:, verify_details:, timings:)
        engine_results << EngineResult.new(
          engine: engine,
          prepare_ok: prepare_ok,
          verify_ok: verify_ok,
          prepare_details: prepare_details,
          verify_details: verify_details,
          timings: timings
        )
      end

      #
      # True if *all* engines passed both prepare and verify
      #
      def ok?
        engine_results.all? { |r| r.prepare_ok && r.verify_ok }
      end

      #
      # True if *any* engine failed either prepare or verify
      #
      def failed?
        !ok?
      end

      #
      # Convenience list of failures for report generation
      #
      def failures
        engine_results.select { |r| !(r.prepare_ok && r.verify_ok) }
      end

      #
      # List of engines in order
      #
      def engines
        engine_results.map(&:engine)
      end
    end
  end
end
