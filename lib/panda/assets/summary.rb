# frozen_string_literal: true

module Panda
  module Assets
    class Summary
      Entry = Struct.new(
        :engine,
        :prepare_ok,
        :verify_ok,
        :details,
        keyword_init: true
      )

      attr_reader :entries

      def initialize
        @entries = []
      end

      def add(engine:, prepare_ok:, verify_ok:, details:)
        entries << Entry.new(
          engine: engine,
          prepare_ok: prepare_ok,
          verify_ok: verify_ok,
          details: details
        )
      end

      def failed?
        entries.any? { |e| !e.prepare_ok || !e.verify_ok }
      end
    end
  end
end
