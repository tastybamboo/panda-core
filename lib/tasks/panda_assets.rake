# frozen_string_literal: true

require "panda/assets/runner"

namespace :panda do
  namespace :assets do
    desc "Prepare + verify dummy assets for all Panda modules"
    task prepare_and_verify_all: :environment do
      Panda::Assets::Runner.run_all!
    end
  end
end
