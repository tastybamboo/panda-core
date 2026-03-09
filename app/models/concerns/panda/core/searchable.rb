# frozen_string_literal: true

module Panda
  module Core
    module Searchable
      extend ActiveSupport::Concern

      included do
        class_attribute :searchable_config, default: {}
      end

      class_methods do
        def searchable(&block)
          config = SearchableConfig.new
          block.call(config)
          self.searchable_config = config.to_h

          # Auto-register with SearchRegistry
          Panda::Core::SearchRegistry.register(
            name: searchable_config[:group]&.parameterize || model_name.plural,
            search_class: self
          )
        end

        def admin_search(query, limit: 5)
          config = searchable_config
          return [] if config[:fields].blank?

          sanitized_query = "%#{sanitize_sql_like(query)}%"
          conditions = config[:fields].map { |f| "#{table_name}.#{f} ILIKE :q" }.join(" OR ")
          records = where(conditions, q: sanitized_query).limit(limit)

          records.map do |record|
            {
              name: config[:display]&.call(record) || record.to_s,
              description: config[:description]&.call(record),
              href: config[:path]&.call(record)
            }
          end
        end
      end
    end

    class SearchableConfig
      KEYS = %i[fields display description path icon group].freeze

      def initialize
        @config = {}
      end

      KEYS.each do |key|
        define_method(key) do |value = nil|
          if value.nil?
            @config[key]
          else
            @config[key] = value
          end
        end
      end

      def to_h
        @config.dup
      end
    end
  end
end
