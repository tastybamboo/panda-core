# frozen_string_literal: true

require "panda/core/testing/assets/runner"

namespace :panda do
  namespace :core do
    namespace :assets do
      desc "Prepare Panda Core dummy assets (Propshaft, JS copy, importmap)"
      task prepare_dummy: :environment do
        Panda::Core::Testing::Assets::Runner.new(:core).prepare
      end

      desc "Verify Panda Core dummy assets (manifest + importmap + HTTP checks)"
      task verify_dummy: :environment do
        Panda::Core::Testing::Assets::Runner.new(:core).verify
      end

      desc "Full Core dummy asset pipeline (prepare + verify)"
      task dummy: :environment do
        Panda::Core::Testing::Assets::Runner.new(:core).run
      end

      # Allow CMS to call core’s verification in its own CI
      task prepare_and_verify_dummy: [:prepare_dummy, :verify_dummy]
    end
  end
end
