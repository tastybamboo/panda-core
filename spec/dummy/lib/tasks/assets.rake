# frozen_string_literal: true

# Stub asset tasks for test environment
# This allows tailwindcss-rails to load without errors
namespace :assets do
  desc "Precompile assets (stub for test environment)"
  task precompile: :environment do
    # No-op in test environment
  end

  desc "Clean assets (stub for test environment)"
  task clean: :environment do
    # No-op in test environment
  end

  desc "Clobber assets (stub for test environment)"
  task clobber: :environment do
    # No-op in test environment
  end
end
