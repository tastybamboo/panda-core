# frozen_string_literal: true

require "panda/core/testing/rspec_config"
require "panda/core/testing/omniauth_helpers"
require "panda/core/testing/capybara_config"

RSpec.configure do |config|
  # Apply Panda Core RSpec configuration
  Panda::Core::Testing::RSpecConfig.configure(config)
  Panda::Core::Testing::RSpecConfig.setup_matchers

  # Configure Capybara
  Panda::Core::Testing::CapybaraConfig.configure

  # Include helpers
  config.include Panda::Core::Testing::OmniAuthHelpers, type: :system
  config.include Panda::Core::Testing::CapybaraConfig::Helpers, type: :system
end
