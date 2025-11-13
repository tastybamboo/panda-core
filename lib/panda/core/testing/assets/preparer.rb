# frozen_string_literal: true

require "fileutils"

module Panda
  module Core
    module Testing
      module Assets
        class Preparer
          attr_reader :config, :report

          def initialize(config, report)
            @config = config
            @report = report
          end

          def prepare!
            ok = true

            report.section("#{config.engine_label}: Propshaft compile")

            propshaft_ok = report.time(:propshaft) { compile_propshaft }
            report.check(:prepare_propshaft, propshaft_ok)
            ok &&= propshaft_ok

            if propshaft_ok
              copy_ok = report.time(:copy_js) { copy_engine_js }
              report.check(:prepare_copy_js, copy_ok)
              ok &&= copy_ok

              importmap_ok = report.time(:importmap_generate) { generate_importmap }
              report.check(:prepare_importmap, importmap_ok)
              ok &&= importmap_ok
            end

            report.time(:total_prepare) { ok } # just record accumulated time

            ok
          end

          private

          def env_hash
            {"RAILS_ENV" => config.rails_env}
          end

          def compile_propshaft
            report.log("• Compiling Propshaft assets in dummy app (RAILS_ENV=#{config.rails_env})")

            Dir.chdir(config.dummy_root) do
              system(env_hash, "bundle exec rails assets:clobber") # ignore failure
              success = system(env_hash, "bundle exec rails assets:precompile")

              unless success
                report.log("✗ Propshaft assets failed to compile")
                return false
              end

              report.log("   ✓ Propshaft assets compiled")
              true
            end
          end

          def copy_engine_js
            report.log("• Copying engine JS modules into dummy app")

            engine_js = config.engine_root.join("app/javascript", config.engine_js_subpath)
            dummy_js = config.dummy_root.join("app/javascript", config.engine_js_subpath)

            unless engine_js.directory?
              report.log("   ! Engine JS directory missing: #{engine_js}")
              return true # not fatal – some engines may be CSS-only
            end

            FileUtils.mkdir_p(dummy_js)
            FileUtils.cp_r(Dir["#{engine_js}/*"], dummy_js)
            report.log("   ✓ Copied JS from #{engine_js} to #{dummy_js}")
            true
          end

          def generate_importmap
            report.log("• Generating importmap.json from dummy Rails app")

            Dir.chdir(config.dummy_root) do
              require config.dummy_root.join("config/environment")

              json = Rails.application.importmap.to_json(
                resolver: ActionController::Base.helpers
              )

              output_dir = config.dummy_root.join("public/assets")
              FileUtils.mkdir_p(output_dir)

              path = output_dir.join("importmap.json")
              File.write(path, json)

              report.log("   ✓ Wrote #{path}")
              true
            end
          rescue => e
            report.log("   ✗ Failed to generate importmap.json: #{e.class}: #{e.message}")
            false
          end
        end
      end
    end
  end
end
