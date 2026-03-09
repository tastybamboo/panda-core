# frozen_string_literal: true

module Panda
  module Core
    class SearchRegistry
      @providers = []

      class << self
        attr_reader :providers

        # Register a search provider (idempotent — overwrites any existing provider with the same name)
        # @param name [String] Provider name (e.g., "pages", "posts")
        # @param search_class [Class] Class that responds to .editor_search(query, limit:)
        #   and optionally .admin_search(query, limit:) for richer global search results
        def register(name:, search_class:)
          @providers.reject! { |p| p[:name] == name }
          @providers << {name: name, search_class: search_class}
        end

        # Search all registered providers (editor format)
        # @param query [String] Search query
        # @param limit [Integer] Max results per provider
        # @return [Array<Hash>] Array of { href:, name:, description: }
        def search(query, limit: 5)
          return [] if query.blank?

          @providers.flat_map do |provider|
            provider[:search_class].editor_search(query, limit: limit)
          rescue => e
            Rails.logger.warn("[panda-core] Search provider #{provider[:name]} failed: #{e.message}") if defined?(Rails.logger)
            []
          end
        end

        # Search all registered providers (admin format with grouping)
        # @param query [String] Search query
        # @param limit [Integer] Max results per provider
        # @return [Hash] { groups: [{ name:, icon:, results: [{ href:, name:, description: }] }] }
        def admin_search(query, limit: 5)
          return {groups: []} if query.blank?

          groups = @providers.filter_map do |provider|
            klass = provider[:search_class]
            next unless klass.respond_to?(:admin_search)

            results = klass.admin_search(query, limit: limit)
            next if results.empty?

            config = klass.respond_to?(:searchable_config) ? klass.searchable_config : {}
            {
              name: config[:group] || provider[:name].to_s.titleize,
              icon: config[:icon],
              results: results
            }
          rescue => e
            Rails.logger.warn("[panda-core] Admin search provider #{provider[:name]} failed: #{e.message}") if defined?(Rails.logger)
            nil
          end

          {groups: groups}
        end

        def reset!
          @providers = []
        end
      end
    end
  end
end
