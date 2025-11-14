# frozen_string_literal: true

require "panda/assets/runner"

namespace :panda do
  namespace :assets do
    desc "Prepare dummy assets for Panda Core ONLY"
    task prepare_core: :environment do
      Panda::Assets::Runner.prepare(:core)
    end

    desc "Verify dummy assets for Panda Core ONLY"
    task verify_core: :environment do
      Panda::Assets::Runner.verify(:core)
    end

    desc "Prepare + verify dummy assets for Panda Core ONLY"
    task prepare_and_verify_core: :environment do
      Panda::Assets::Runner.run(:core)
    end

    desc "Prepare + verify assets for Core + ALL registered Panda modules"
    task prepare_and_verify_all: :environment do
      Panda::Assets::Runner.run_all!
    end
  end
end
