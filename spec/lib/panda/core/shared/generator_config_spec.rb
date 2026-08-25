# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::Shared::GeneratorConfig do
  describe "the engine's uuid primary key preference" do
    it "applies to generators run inside the engine" do
      options = Panda::Core::Engine.config.generators.options

      expect(options[:active_record][:primary_key_type]).to eq(:uuid)
    end

    # Rails::Engine::Configuration takes a deep copy of the shared app_generators
    # object, so an engine's config.generators is its own. config.app_generators is
    # the one that leaks. That distinction is load bearing: Rails' own Active
    # Storage and Action Text migrations read Rails.configuration.generators at
    # migration time to decide their primary and foreign key types, so a gem that
    # set it would be silently retyping the host app's active_storage_blobs.
    #
    # Whether Active Storage uses bigint or uuid keys is the host app's decision.
    # panda-core reads it (see CreatePandaCoreFileCategories) and never sets it.
    it "does not leak into the host application's generator configuration" do
      options = Rails.configuration.generators.options

      expect(options[:active_record][:primary_key_type]).to be_nil
    end

    it "does not set app_generators, which would leak into the host application" do
      options = Panda::Core::Engine.config.app_generators.options

      expect(options[:active_record][:primary_key_type]).to be_nil
    end
  end
end
