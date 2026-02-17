require "rails_helper"

RSpec.describe Panda::Core::FeatureFlag, type: :model do
  describe "validations" do
    subject { described_class.new(key: "test.flag") }

    it { should validate_presence_of(:key) }
    it { should validate_uniqueness_of(:key) }
  end

  describe ".enabled?" do
    it "returns true for enabled flags" do
      described_class.create!(key: "test.enabled", enabled: true)
      expect(described_class.enabled?("test.enabled")).to be true
    end

    it "returns false for disabled flags" do
      described_class.create!(key: "test.disabled", enabled: false)
      expect(described_class.enabled?("test.disabled")).to be false
    end

    it "returns false for unknown keys" do
      expect(described_class.enabled?("nonexistent.key")).to be false
    end

    it "caches the result" do
      described_class.create!(key: "test.cached", enabled: true)

      # First call populates cache
      described_class.enabled?("test.cached")

      # Subsequent calls should hit cache, not DB
      expect(Rails.cache).to receive(:fetch)
        .with("panda_core:feature_flag:test.cached", expires_in: 1.minute)
        .and_return(true)

      described_class.enabled?("test.cached")
    end
  end

  describe ".enable!" do
    it "enables a disabled flag" do
      flag = described_class.create!(key: "test.toggle", enabled: false)
      described_class.enable!("test.toggle")
      expect(flag.reload.enabled).to be true
    end

    it "clears the cache" do
      described_class.create!(key: "test.cache_clear", enabled: false)
      expect(Rails.cache).to receive(:delete).with("panda_core:feature_flag:test.cache_clear")
      described_class.enable!("test.cache_clear")
    end

    it "raises for unknown keys" do
      expect { described_class.enable!("nonexistent") }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe ".disable!" do
    it "disables an enabled flag" do
      flag = described_class.create!(key: "test.toggle", enabled: true)
      described_class.disable!("test.toggle")
      expect(flag.reload.enabled).to be false
    end

    it "clears the cache" do
      described_class.create!(key: "test.cache_clear", enabled: true)
      expect(Rails.cache).to receive(:delete).with("panda_core:feature_flag:test.cache_clear")
      described_class.disable!("test.cache_clear")
    end
  end

  describe ".toggle!" do
    it "flips an enabled flag to disabled" do
      flag = described_class.create!(key: "test.flip", enabled: true)
      described_class.toggle!("test.flip")
      expect(flag.reload.enabled).to be false
    end

    it "flips a disabled flag to enabled" do
      flag = described_class.create!(key: "test.flip", enabled: false)
      described_class.toggle!("test.flip")
      expect(flag.reload.enabled).to be true
    end

    it "clears the cache" do
      described_class.create!(key: "test.cache_clear", enabled: false)
      expect(Rails.cache).to receive(:delete).with("panda_core:feature_flag:test.cache_clear")
      described_class.toggle!("test.cache_clear")
    end
  end

  describe ".register" do
    it "creates a new flag when key does not exist" do
      flag = described_class.register("new.flag", description: "A new flag", enabled: true)
      expect(flag).to be_persisted
      expect(flag.key).to eq("new.flag")
      expect(flag.description).to eq("A new flag")
      expect(flag.enabled).to be true
    end

    it "does not overwrite an existing flag" do
      described_class.create!(key: "existing.flag", description: "Original", enabled: true)
      flag = described_class.register("existing.flag", description: "Updated", enabled: false)
      expect(flag.description).to eq("Original")
      expect(flag.enabled).to be true
    end

    it "is idempotent" do
      expect {
        described_class.register("idempotent.flag", description: "Test")
        described_class.register("idempotent.flag", description: "Test")
      }.to change(described_class, :count).by(1)
    end
  end
end
