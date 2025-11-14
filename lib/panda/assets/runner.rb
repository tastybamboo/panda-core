# frozen_string_literal: true

require "benchmark"
require_relative "ui"
require_relative "preparer"
require_relative "verifier"

module Panda
  module Assets
    class Runner
      Result = Struct.new(
        :ok,
        :prepare,
        :verify,
        keyword_init: true
      )

      def self.run(engine_key, config)
        new(engine_key, config).run
      end

      def self.prepare(engine_key, config)
        new(engine_key, config).prepare_only
      end

      def self.verify(engine_key, config)
        new(engine_key, config).verify_only
      end

      attr_reader :engine_key, :config

      def initialize(engine_key, config)
        @engine_key = engine_key
        @config = config
      end

      def prepare_only
        preparer.prepare
      end

      def verify_only
        verifier.verify
      end

      def run
        Panda::Assets::UI.banner("Panda #{engine_label} dummy assets – PREPARE + VERIFY")

        prepare_result = preparer.prepare
        checks = {
          prepare_propshaft: prepare_result.errors.none? { |e| e.include?("Propshaft") },
          prepare_copy_js: true,
          prepare_importmap: true
        }

        checks.each { |k, v| prepare_result.errors << k.to_s unless v }

        verify_result = verifier.verify

        ok = prepare_result.ok && verify_result.ok

        Result.new(ok: ok, prepare: prepare_result, verify: verify_result)
      end

      private

      def engine_label
        engine_key.to_s.split("_").map(&:capitalize).join(" ")
      end

      def preparer
        @preparer ||= Panda::Assets::Preparer.new(engine_key, config)
      end

      def verifier
        @verifier ||= Panda::Assets::Verifier.new(engine_key, config)
      end
    end
  end
end
