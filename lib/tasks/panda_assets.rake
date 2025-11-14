# frozen_string_literal: true

# Unified asset pipeline entry-point
require "panda/assets/runner"

namespace :panda do
  namespace :assets do
    desc "Prepare + verify Panda Core and all registered Panda modules"
    task prepare_and_verify_all: :environment do
      # This runs Core + CMS + CMS Pro + Community etc.
      Panda::Assets::Runner.run_all!
    end
  end
end
