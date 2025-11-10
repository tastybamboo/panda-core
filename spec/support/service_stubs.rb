# frozen_string_literal: true

require "tempfile"
require "base64"

# Stub services that make external HTTP requests to prevent them in tests
RSpec.configure do |config|
  config.before(:each) do
    # Stub URI.open to prevent external HTTP requests when downloading avatars
    # This affects AttachAvatarService which downloads avatars from OAuth providers
    # Tests that specifically need real HTTP requests can override this stub
    allow(URI).to receive(:open).and_wrap_original do |original_method, *args, **kwargs, &block|
      url = args[0]

      # Only stub avatar downloads from OAuth providers and test URLs
      if /googleusercontent\.com|githubusercontent\.com|graph\.microsoft\.com|example\.com/.match?(url.to_s)
        # Use the actual test fixture file instead of creating a fake file
        # This ensures compatibility with Active Storage
        fixture_path = Panda::Core::Engine.root.join("spec", "fixtures", "files", "test_image.jpg")
        downloaded_file = File.open(fixture_path, "rb")

        # Add methods that AttachAvatarService expects
        downloaded_file.define_singleton_method(:content_type) { "image/jpeg" }
        downloaded_file.define_singleton_method(:size) { File.size(fixture_path) }

        # Call the block with our file if a block is given
        if block_given?
          result = block.call(downloaded_file)
          downloaded_file.close unless downloaded_file.closed?
          result
        else
          downloaded_file
        end
      else
        # For other URLs, use the original method
        original_method.call(*args, **kwargs, &block)
      end
    end
  end
end
