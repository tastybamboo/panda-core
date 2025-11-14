# frozen_string_literal: true

require "benchmark"
require_relative "ui"
require_relative "preparer"
require_relative "verifier"
require_relative "summary"
require_relative "html_report"

module Panda
  module Assets
    class Runner
      #
      # Support two construction modes:
      #   Runner.new                   → full-suite (all modules)
      #   Runner.new(:core, config)    → single-engine
      #
      def initialize(engine_key = nil, config = {})
        @engine_key = engine_key
        @config = config
      end

      #
      # ────────────────────────────────────────────
      # CLASS METHODS
      # ────────────────────────────────────────────
      #
      class << self
        #
        # Unified CI entrypoint (all modules)
        #
        def run_all!
          new.run_all!
        end

        #
        # Legacy single-engine API
        #
        def run(engine_key, config = {})
          new(engine_key, config).run
        end

        def prepare(engine_key, config = {})
          new(engine_key, config).prepare_only
        end

        def verify(engine_key, config = {})
          new(engine_key, config).verify_only
        end
      end

      #
      # ────────────────────────────────────────────
      # SINGLE ENGINE PIPELINE (legacy)
      # ────────────────────────────────────────────
      #
      def run
        summary = Summary.new

        prepare!(summary, @engine_key)
        verify!(summary, @engine_key)

        HTMLReport.write!(summary)

        summary
      end

      def prepare_only
        summary = Summary.new
        prepare!(summary, @engine_key)
        HTMLReport.write!(summary)
        summary
      end

      def verify_only
        summary = Summary.new
        verify!(summary, @engine_key)
        HTMLReport.write!(summary)
        summary
      end

      #
      # ────────────────────────────────────────────
      # FULL SUITE PIPELINE (CI)
      # ────────────────────────────────────────────
      #
      def run_all!
        summary = Summary.new

        # Core first
        prepare!(summary, :core)
        verify!(summary, :core)

        # All registered modules next
        Panda::Core::ModuleRegistry.registered_modules.each do |name|
          prepare!(summary, name.to_sym)
          verify!(summary, name.to_sym)
        end

        HTMLReport.write!(summary)

        raise "Panda assets pipeline failed" if summary.failed?

        summary
      end

      private

      #
      # Delegation wrappers
      #
      def prepare!(summary, engine_key)
        Preparer.new(summary, engine_key).run
      end

      def verify!(summary, engine_key)
        Verifier.new(summary, engine_key).run
      end
    end
  end
end
