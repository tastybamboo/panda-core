# frozen_string_literal: true

require "benchmark"
require_relative "ui"
require_relative "config"
require_relative "preparer"
require_relative "verifier"
require_relative "summary"
require_relative "html_report"

module Panda
  module Assets
    class Runner
      class << self
        #
        # The entrypoint used by CI:
        #
        def run_all!
          new.run_all!
        end
      end

      def run_all!
        summary = Summary.new

        Config.all.each do |config|
          UI.banner "Preparing #{config[:name]}"
          prep = Preparer.new(config).call

          UI.banner "Verifying #{config[:name]}"
          ver = Verifier.new(config).call

          summary.add(
            engine: config[:name],
            prepare_ok: prep[:ok],
            verify_ok: ver[:ok],
            details: (prep[:details] + ver[:details])
          )
        end

        HTMLReport.write!(summary)

        raise "Panda assets pipeline failed" if summary.failed?

        true
      end
    end
  end
end
