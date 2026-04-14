# frozen_string_literal: true

module Panda
  module Core
    module SqliteSchemaCompatibility
      extend ActiveSupport::Concern

      included do
        initializer "panda_core.sqlite_schema_compatibility" do
          next unless ActiveRecord::Base.configurations.configs_for(env_name: Rails.env).any? { |cfg| cfg.adapter == "sqlite3" }

          require "active_record/connection_adapters/sqlite3_adapter"

          sqlite_adapter = ActiveRecord::ConnectionAdapters::SQLite3Adapter
          unless sqlite_adapter.singleton_class.method_defined?(:native_database_types_with_panda_sqlite_compatibility)
            sqlite_adapter.singleton_class.prepend(Module.new do
              def native_database_types_with_panda_sqlite_compatibility
                super.merge(
                  uuid: { name: "varchar" },
                  jsonb: { name: "json" }
                )
              end
              alias_method :native_database_types, :native_database_types_with_panda_sqlite_compatibility
            end)
          end

          table_definition = ActiveRecord::ConnectionAdapters::SQLite3::TableDefinition
          # Rails' SQLite TableDefinition intentionally omits these helpers, but our
          # cross-database migrations/schema use them. We define them once at boot.
          table_definition.send(:define_column_methods, :uuid) unless table_definition.method_defined?(:uuid)
          table_definition.send(:define_column_methods, :jsonb) unless table_definition.method_defined?(:jsonb)
        end
      end
    end
  end
end
