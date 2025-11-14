# frozen_string_literal: true

module Panda
  module Core
    module Testing
      module Assets
        class Preparer
          attr_reader :engine, :dummy_root, :engine_root

          def initialize(engine)
            @engine = engine.to_sym
            @engine_root = (engine == :core) ?
                             Panda::Core::Engine.root :
                             Panda::CMS::Engine.root

            @dummy_root = resolve_dummy_root
          end

          def resolve_dummy_root
            root = Rails.root
            return root if root.basename.to_s == "dummy"

            candidate = root.join("spec/dummy")
            return candidate if candidate.exist?

            raise "❌ Could not locate dummy root (looked for #{candidate})"
          end

          def call
            prepare_propshaft
            copy_engine_js
            generate_importmap
          end

          # --------------------------------------------------------------
          # Steps
          # --------------------------------------------------------------

          def prepare_propshaft
            puts "• Compiling Propshaft assets in dummy app (RAILS_ENV=test)"

            Dir.chdir(dummy_root) do
              system("bundle exec rails assets:clobber RAILS_ENV=test")
              ok = system("bundle exec rails assets:precompile RAILS_ENV=test")
              raise "❌ Propshaft failed" unless ok
            end

            puts "   ✓ Propshaft assets compiled"
          end

          def copy_engine_js
            puts "• Copying engine JS modules into dummy app"

            src = engine_root.join("app/javascript/panda/#{engine}")
            dst = dummy_root.join("app/javascript/panda/#{engine}")

            FileUtils.mkdir_p(dst)
            FileUtils.cp_r(src.children, dst)

            puts "   ✓ Copied JS from #{src} to #{dst}"
          end

          def generate_importmap
            puts "• Generating importmap.json from dummy Rails app"

            Dir.chdir(dummy_root) do
              require dummy_root.join("config/environment")
              json = Rails.application.importmap.to_json(
                resolver: ActionController::Base.helpers
              )
              outdir = dummy_root.join("public/assets")
              FileUtils.mkdir_p(outdir)
              File.write(outdir.join("importmap.json"), json)
            end

            puts "   ✓ Wrote #{dummy_root.join("public/assets/importmap.json")}"
          end
        end
      end
    end
  end
end
