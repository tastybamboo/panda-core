# frozen_string_literal: true

require "panda/core/testing/assets/runner"

namespace :panda do
  namespace :core do
    namespace :assets do
      desc "Prepare Panda Core dummy assets (compile + importmap + copy JS)"
      task prepare_dummy: :environment do
        Panda::Core::Testing::Assets::Runner.prepare(:core)
      end

      desc "Verify Panda Core dummy assets (manifest + importmap + HTTP checks)"
      task verify_dummy: :environment do
        Panda::Core::Testing::Assets::Runner.verify(:core)
      end

      desc "Full Core dummy asset pipeline (prepare + verify)"
      task dummy: :environment do
        Panda::Core::Testing::Assets::Runner.run(:core)
      end
    end
  end
end
