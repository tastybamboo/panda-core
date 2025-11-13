# frozen_string_literal: true

require "fileutils"

module Panda
  module Core
    module Testing
      module Assets
        class Preparer
          Result = Struct.new(:ok, :errors, :timings, keyword_init: true)

          ENGINE_CONFIG = {
            core: {
              name: "Panda Core",
              js_source: lambda {
                if defined?(Panda::Core)
                  Panda::Core::Engine.root.join("app/javascript/panda/core")
                end
              },
              js_target_subdir: File.join("app/javascript/panda/core")
            },
            cms: {
              name: "Panda CMS",
              js_source: lambda {
                if defined?(Panda::CMS)
                  Panda::CMS::Engine.root.join("app/javascript/panda/cms")
                end
              },
              js_target_subdir: File.join("app/javascript/panda/cms")
            }
          }.freeze

          def self.run(engine)
            new(engine).run
          end

          def initialize(engine)
            @engine = engine.to_sym
            @errors = []
            @timings = {}
          end

          attr_reader :errors, :timings

          def run
            t0 = now

            prepare_propshaft
            copy_engine_js
            generate_importmap

            total = now - t0
            timings[:total_prepare] = total

            Result.new(ok: errors.empty?, errors: errors, timings: timings)
          end

          private

          def config
            ENGINE_CONFIG.fetch(@engine)
          rescue KeyError
            raise "Unknown engine for asset preparation: #{@engine.inspect}"
          end

          def dummy_root
            @dummy_root ||= begin
              root = Rails.root
              if root.basename.to_s == "dummy"
                root
              else
                candidate = root.join("spec/dummy")
                raise "Cannot find dummy root at #{candidate}" unless candidate.exist?
                candidate
              end
            end
          end

          def now
            Process.clock_gettime(Process::CLOCK_MONOTONIC)
          end

          def prepare_propshaft
            t = now
            UI.banner("#{config[:name]}: Propshaft compile", status: :ok)
            UI.step("Compiling Propshaft assets in dummy app (RAILS_ENV=test)")

            Dir.chdir(dummy_root) do
              system("bundle exec rails assets:clobber RAILS_ENV=test")
              success = system("bundle exec rails assets:precompile RAILS_ENV=test")
              if success
                UI.ok("Propshaft assets compiled")
              else
                errors << {where: "propshaft", message: "assets:precompile failed"}
              end
            end
          rescue => e
            errors << {where: "propshaft", message: e.message}
            UI.error("Propshaft compile error: #{e.message}")
          ensure
            timings[:propshaft] = now - t
          end

          def copy_engine_js
            t = now
            UI.step("Copying engine JS modules into dummy app")

            src = config[:js_source]&.call
            unless src && Dir.exist?(src)
              UI.warn("No JS source directory found for #{@engine} (#{src})")
              return
            end

            dest = dummy_root.join(config[:js_target_subdir])
            FileUtils.mkdir_p(dest)

            # Remove old content
            Dir.glob(File.join(dest.to_s, "*")).each do |path|
              FileUtils.rm_rf(path)
            end

            FileUtils.cp_r(Dir.glob(File.join(src.to_s, "*")), dest)

            UI.ok("Copied JS from #{src} to #{dest}")
          rescue => e
            errors << {where: "copy_js", message: e.message}
            UI.error("Copy JS error: #{e.message}")
          ensure
            timings[:copy_js] = now - t
          end

          def generate_importmap
            t = now
            UI.step("Generating importmap.json from dummy Rails app")

            Dir.chdir(dummy_root) do
              # Load full Rails env for importmap
              require dummy_root.join("config/environment")
              json = Rails.application.importmap.to_json(
                resolver: ActionController::Base.helpers
              )

              output_dir = dummy_root.join("public/assets")
              FileUtils.mkdir_p(output_dir)

              path = output_dir.join("importmap.json")
              File.write(path, json)
              UI.ok("Wrote #{path}")
            end
          rescue => e
            errors << {where: "importmap_generate", message: e.message}
            UI.error("Importmap generation error: #{e.message}")
          ensure
            timings[:importmap_generate] = now - t
          end
        end
      end
    end
  end
end
