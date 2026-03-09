# frozen_string_literal: true

module Panda
  module Core
    module Importable
      extend ActiveSupport::Concern

      class FieldDefinition
        attr_reader :name, :label, :required, :transform

        def initialize(name, label:, required: false, transform: nil)
          @name = name
          @label = label
          @required = required
          @transform = transform || ->(v) { v }
        end
      end

      class Configuration
        attr_reader :field_definitions

        def initialize
          @field_definitions = []
        end

        def field(name, label: name.to_s.humanize, required: false, &transform)
          @field_definitions << FieldDefinition.new(
            name, label: label, required: required,
            transform: block_given? ? transform : nil
          )
        end
      end

      included do
        class_attribute :import_configuration, instance_writer: false
        self.import_configuration = Configuration.new
      end

      class_methods do
        def importable(&block)
          config = Configuration.new
          block.call(config)
          self.import_configuration = config
        end

        def import_field_definitions
          import_configuration.field_definitions
        end

        def import_row(row_data, column_mapping)
          attrs = {}
          errors = []

          column_mapping.each do |csv_col, field_name|
            next if field_name.blank?
            defn = import_field_definitions.find { |d| d.name.to_s == field_name.to_s }
            next unless defn

            raw_value = row_data[csv_col]
            begin
              attrs[defn.name] = defn.transform.call(raw_value)
            rescue => e
              errors << "#{defn.label}: #{e.message}"
            end
          end

          import_field_definitions.select(&:required).each do |defn|
            if attrs[defn.name].blank?
              errors << "#{defn.label} is required"
            end
          end

          [attrs, errors]
        end
      end
    end
  end
end
