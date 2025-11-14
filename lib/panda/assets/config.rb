# frozen_string_literal: true

module Panda
  module Assets
    class Config
      def self.for_core
        {
          engine_key: :core,
          engine_root: Panda::Core::Engine.root,
          dummy_root: Rails.root.join("spec/dummy"),
          public_root: Rails.root.join("spec/dummy/public"),
          javascript_paths: [
            "app/javascript/panda/core"
          ],
          vendor_paths: [
            "vendor/javascript"
          ]
        }
      end

      def self.for_all
        [for_core] # later: append CMS, CMS Pro, Community…
      end
    end
  end
end
