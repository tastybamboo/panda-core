# frozen_string_literal: true

module Panda
  module Core
    module SqliteSchemaCompatibility
      extend ActiveSupport::Concern

      included do
        initializer "panda_core.sqlite_schema_compatibility" do
          next unless ActiveRecord::Base.configurations.configs_for(env_name: Rails.env).any? { |cfg| cfg.adapter == "sqlite3" }

          require "active_record/connection_adapters/sqlite3_adapter"

          sqlite_types = ActiveRecord::ConnectionAdapters::SQLite3Adapter::NATIVE_DATABASE_TYPES
          sqlite_types[:uuid] ||= { name: "varchar" }
          sqlite_types[:jsonb] ||= { name: "json" }

          table_definition = ActiveRecord::ConnectionAdapters::SQLite3::TableDefinition
          table_definition.send(:define_column_methods, :uuid) unless table_definition.method_defined?(:uuid)
          table_definition.send(:define_column_methods, :jsonb) unless table_definition.method_defined?(:jsonb)
        end
      end
    end
  end
end
