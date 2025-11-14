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

        #
        # 🔥 Add GitHub step summary (visible in Actions UI)
        #
        if ENV["GITHUB_STEP_SUMMARY"]
          File.open(ENV["GITHUB_STEP_SUMMARY"], "a") do |f|
            f.puts "# Panda Asset Pipeline Summary"
            f.puts

            summary.entries.each do |e|
              ok = e.prepare_ok && e.verify_ok

              f.puts "## #{e.engine.to_s.capitalize}"
              f.puts ok ? "✔ **OK**" : "✘ **FAILED**"
              f.puts

              e.details.each { |d| f.puts "- #{d}" }
              f.puts
            end

            # Optional: link to HTML artifact
            f.puts "---"
            f.puts "📄 **Full HTML Report:** _uploaded as artifact `panda-assets-report`_"
            f.puts
          end
        end

        #
        # Fail CI if anything failed
        #
        if summary.failed?
          raise "Panda assets pipeline failed"
        end

        true
      end
    end
  end
end
