# frozen_string_literal: true

module Panda
  module Assets
    class ModuleRegistry
      @modules = {}

      class << self
        def register(name, root:, javascript_paths: [], vendor_paths: [])
          @modules[name.to_sym] = {
            name: name.to_sym,
            root: root,
            javascript_paths: javascript_paths,
            vendor_paths: vendor_paths
          }
        end

        def all
          @modules.values
        end
      end
    end
  end
end
