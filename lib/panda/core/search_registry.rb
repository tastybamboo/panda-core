# frozen_string_literal: true

module Panda
  module Core
    class SearchRegistry
      @providers = []

      class << self
        attr_reader :providers

        # Register a search provider
        # @param name [String] Provider name (e.g., "pages", "posts")
        # @param search_class [Class] Class that responds to .editor_search(query, limit:)
        def register(name:, search_class:)
          @providers << {name: name, search_class: search_class}
        end

        # Search all registered providers
        # @param query [String] Search query
        # @param limit [Integer] Max results per provider
        # @return [Array<Hash>] Array of { href:, name:, description: }
        def search(query, limit: 5)
          return [] if query.blank?

          @providers.flat_map do |provider|
            provider[:search_class].editor_search(query, limit: limit)
          rescue => e
            Rails.logger.warn("[Panda Core] Search provider #{provider[:name]} failed: #{e.message}")
            []
          end
        end

        def reset!
          @providers = []
        end
      end
    end
  end
end
