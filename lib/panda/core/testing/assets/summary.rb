# frozen_string_literal: true

module Panda
  module Core
    module Testing
      module Assets
        module Summary
          module_function

          def write(engine_name:, ok:, timings:, checks:)
            summary_path = ENV["GITHUB_STEP_SUMMARY"]
            return unless summary_path

            File.open(summary_path, "a") do |f|
              f.puts "## #{engine_name} Asset Verification"
              f.puts
              f.puts "- Status: #{ok ? "✅ Success" : "❌ Failed"}"
              f.puts "- Total time: #{format_seconds(timings[:total])}" if timings[:total]
              f.puts
              if timings.any?
                f.puts "### ⏱ Timing"
                timings.each do |k, v|
                  next if k == :total
                  f.puts "- #{k.to_s.tr("_", " ").capitalize}: #{format_seconds(v)}"
                end
                f.puts
              end

              if checks.any?
                f.puts "### ✅ Checks"
                checks.each do |check|
                  status = check[:ok] ? "✅" : "❌"
                  f.puts "- #{status} #{check[:name]}"
                end
                f.puts
              end
            end
          rescue => e
            warn "⚠️ Could not write GitHub summary: #{e.message}"
          end

          def format_seconds(sec)
            return "-" unless sec
            format("%.2fs", sec)
          end
        end
      end
    end
  end
end
