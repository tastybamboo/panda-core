# frozen_string_literal: true

require "rails_helper"

RSpec.describe Panda::Core::FeatureFlagHelper, type: :helper do
  describe "#feature_flag_enabled?" do
    it "delegates to FeatureFlag.enabled?" do
      expect(Panda::Core::FeatureFlag).to receive(:enabled?).with(:test_flag).and_return(true)
      expect(helper.feature_flag_enabled?(:test_flag)).to be true
    end

    it "returns false for disabled flags" do
      expect(Panda::Core::FeatureFlag).to receive(:enabled?).with(:disabled_flag).and_return(false)
      expect(helper.feature_flag_enabled?(:disabled_flag)).to be false
    end
  end
end
