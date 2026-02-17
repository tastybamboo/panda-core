# frozen_string_literal: true

module Panda
  module Core
    module FeatureFlagHelper
      def feature_flag_enabled?(key)
        Panda::Core::FeatureFlag.enabled?(key)
      end
    end
  end
end
