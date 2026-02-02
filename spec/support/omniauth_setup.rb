# frozen_string_literal: true

# Configure authentication providers for tests
RSpec.configure do |config|
  config.around(:each, type: :controller) do |example|
    original_providers = Panda::Core.config.authentication_providers.dup
    # Set up test authentication providers
    Panda::Core.config.authentication_providers = {
      google_oauth2: {
        client_id: "test_client_id",
        client_secret: "test_client_secret",
        options: {}
      }
    }
    example.run
  ensure
    Panda::Core.config.authentication_providers = original_providers
  end
end
