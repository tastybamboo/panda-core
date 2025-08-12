# frozen_string_literal: true

module Panda
  module Core
    class Breadcrumb
      attr_reader :name, :path

      def initialize(name, path)
        @name = name
        @path = path
      end

      # Alias for compatibility
      alias_method :label, :name
    end
  end
end
