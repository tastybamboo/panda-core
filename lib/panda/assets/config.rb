# frozen_string_literal: true

require_relative "module_registry"

module Panda
  module Assets
    class Config
      class << self
        def core_config
          {
            name: :core,
            root: Panda::Core::Engine.root,
            dummy_root: Rails.root.join("spec/dummy"),
            public_root: Rails.root.join("spec/dummy/public"),
            javascript_paths: ["app/javascript/panda/core"],
            vendor_paths: ["vendor/javascript"]
          }
        end

        def all
          [
            core_config,
            *dynamic_modules
          ]
        end

        def dynamic_modules
          ModuleRegistry.all.map do |mod|
            {
              name: mod[:name],
              root: mod[:root],
              dummy_root: Rails.root.join("spec/dummy"),
              public_root: Rails.root.join("spec/dummy/public"),
              javascript_paths: mod[:javascript_paths],
              vendor_paths: mod[:vendor_paths]
            }
          end
        end
      end
    end
  end
end
