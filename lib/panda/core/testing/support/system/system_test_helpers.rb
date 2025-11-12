# frozen_string_literal: true

require_relative "cuprite_helpers"
require_relative "better_system_tests"

# Generic system test helpers for Cuprite-based testing
# These methods work for any Rails application using Cuprite

module Panda
  module Core
    module Testing
      module SystemTestHelpers
        include CupriteHelpers
        include BetterSystemTests
      end
    end
  end
end

# Configure RSpec to use these helpers
RSpec.configure do |config|
  config.include Panda::Core::Testing::SystemTestHelpers, type: :system

  # Configure enhanced system test behavior
  Panda::Core::Testing::BetterSystemTests::ClassMethods.configure_better_system_tests!
end
