# frozen_string_literal: true

module Panda
  module Core
    class ComponentRegistry
      class << self
        def components
          @components ||= {}
        end

        def register(name, component_class)
          components[name.to_sym] = component_class
        end

        def unregister(name)
          components.delete(name.to_sym)
        end

        def get(name)
          components[name.to_sym]
        end

        def all
          components
        end

        def clear!
          @components = {}
        end

        def registered?(name)
          components.key?(name.to_sym)
        end
      end
    end
  end
end
