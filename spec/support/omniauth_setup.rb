# frozen_string_literal: true

# Configure authentication providers for tests
RSpec.configure do |config|
  config.before(:each, type: :controller) do
    # Set up test authentication providers
    Panda::Core.configure do |core_config|
      core_config.authentication_providers = {
        google_oauth2: {
          client_id: "test_client_id",
          client_secret: "test_client_secret",
          options: {}
        }
      }
    end
  end
end