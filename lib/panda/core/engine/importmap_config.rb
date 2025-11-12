# frozen_string_literal: true

module Panda
  module Core
    class Engine < ::Rails::Engine
      # Importmap configuration
      module ImportmapConfig
        extend ActiveSupport::Concern

        included do
          # Load the engine's importmap
          # This keeps the engine's JavaScript separate from the app's importmap
          initializer "panda_core.importmap", before: "importmap" do |app|
            Panda::Core.importmap = Importmap::Map.new.tap do |map|
              map.draw(Panda::Core::Engine.root.join("config/importmap.rb"))
            end
          end
        end
      end
    end
  end
end
