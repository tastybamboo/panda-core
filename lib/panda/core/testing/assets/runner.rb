# frozen_string_literal: true

require "fileutils"
require_relative "ui"
require_relative "summary"
require_relative "report"
require_relative "preparer"
require_relative "verifier"

module Panda
  module Core
    module Testing
      module Assets
        class Runner
          ENGINE_NAMES = {
            core: "Panda Core",
            cms: "Panda CMS"
          }.freeze

          def self.prepare(engine)
            new(engine).prepare_only
          end

          def self.verify(engine)
            new(engine).verify_only
          end

          def self.run(engine)
            new(engine).run
          end

          def initialize(engine)
            @engine = engine.to_sym
            @engine_name = ENGINE_NAMES.fetch(@engine) { "Unknown engine (#{@engine})" }
          end

          def prepare_only
            UI.banner("#{@engine_name} dummy assets – PREPARE", status: :ok)
            prep = Preparer.run(@engine)
            timings = prep.timings.merge(total: prep.timings[:total_prepare])
            checks = [{name: "prepare", ok: prep.ok}]
            Summary.write(engine_name: @engine_name, ok: prep.ok, timings: timings, checks: checks)
            exit(1) unless prep.ok
          end

          def verify_only
            UI.banner("#{@engine_name} dummy assets – VERIFY", status: :ok)
            verify = Verifier.run(@engine)

            timings = verify.timings.merge(total: verify.timings[:total_verify])
            Summary.write(engine_name: @engine_name, ok: verify.ok, timings: timings, checks: verify.checks)

            write_html_report(verify)

            unless verify.ok
              UI.error("Asset verification failed")
              exit(1)
            end
          end

          def run
            t0 = now
            UI.banner("#{@engine_name} dummy assets – PREPARE + VERIFY", status: :ok)

            prep = Preparer.run(@engine)
            verify = Verifier.run(@engine)

            total = now - t0

            timings = prep.timings.merge(verify.timings)
            timings[:total] = total

            checks = verify.checks.dup
            checks.unshift({name: "prepare", ok: prep.ok})

            ok = prep.ok && verify.ok

            UI.divider
            UI.step("Summary for #{@engine_name}")
            UI.ok("Prepare phase OK") if prep.ok
            UI.error("Prepare phase FAILED") unless prep.ok
            UI.ok("Verify phase OK") if verify.ok
            UI.error("Verify phase FAILED") unless verify.ok

            UI.step("Timings:")
            timings.each do |k, v|
              UI.ok("#{k}: #{format("%.2fs", v)}")
            end

            Summary.write(engine_name: @engine_name, ok: ok, timings: timings, checks: checks)
            write_html_report(verify, timings: timings, ok: ok)

            exit(1) unless ok
          end

          private

          def now
            Process.clock_gettime(Process::CLOCK_MONOTONIC)
          end

          def dummy_root
            @dummy_root ||= begin
              root = Rails.root
              if root.basename.to_s == "dummy"
                root
              else
                candidate = root.join("spec/dummy")
                candidate.exist? ? candidate : root
              end
            end
          end

          def write_html_report(verify, timings: nil, ok: nil)
            result = {
              ok: ok.nil? ? verify.ok : ok,
              timings: timings || verify.timings,
              checks: verify.checks,
              errors: verify.errors,
              http_failures: verify.http_failures
            }

            path = Report.write(
              dummy_root: dummy_root.to_s,
              engine_name: @engine_name,
              result: result
            )

            if path
              UI.step("HTML report written to #{path}")
            end
          end
        end
      end
    end
  end
end
