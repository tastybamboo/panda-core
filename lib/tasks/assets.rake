# frozen_string_literal: true

require "panda/core/testing/assets/runner"

namespace :panda do
  namespace :core do
    namespace :assets do
      desc "Prepare Panda Core dummy assets (Propshaft + JS copy + importmap)"
      task prepare_dummy: :environment do
        runner = Panda::Core::Testing::Assets::Runner.new(:core)
        runner.prepare
      end

      desc "Verify Panda Core dummy assets (manifest + importmap + HTTP checks)"
      task verify_dummy: :environment do
        runner = Panda::Core::Testing::Assets::Runner.new(:core)
        runner.verify
      end

      desc "Prepare + verify Panda Core dummy assets (full pipeline)"
      task dummy: :environment do
        Panda::Core::Testing::Assets::Runner.new(:core).run
      end

      # Backwards-compatible alias for CI
      desc "Prepare + verify Panda Core assets (alias for panda:core:assets:dummy)"
      task prepare_and_verify_dummy: :environment do
        Rake::Task["panda:core:assets:dummy"].invoke
      end
    end
  end
end
