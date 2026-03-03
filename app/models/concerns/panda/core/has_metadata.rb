# frozen_string_literal: true

module Panda
  module Core
    # Concern for models with a JSONB `metadata` column.
    #
    # Provides a DSL to declare typed metadata fields that auto-generate
    # scopes, predicates, and virtual attribute setters.
    #
    #   class User < ApplicationRecord
    #     include HasMetadata
    #
    #     metadata_field :internal, type: :boolean, filterable: true,
    #       label: "Visibility", default_scope: :external,
    #       filter_options: [["All Users", ""], ["Staff Users", "internal"], ["External Users", "external"]]
    #   end
    #
    #   User.internal          # => scope
    #   User.external          # => scope
    #   user.internal?         # => true/false
    #   user.mark_as_internal! # => saves
    #   user.mark_as_external! # => saves
    #   user.internal = "1"    # => virtual setter for forms
    #
    module HasMetadata
      extend ActiveSupport::Concern

      included do
        class_attribute :_metadata_fields, default: {}

        scope :with_metadata, ->(key, value) {
          if connection.adapter_name == "PostgreSQL"
            where("metadata @> ?", {key.to_s => value}.to_json)
          else
            where("json_extract(metadata, ?) = ?", "$.#{key}", json_cast(value))
          end
        }
      end

      class_methods do
        # Declare a metadata field with auto-generated scopes and accessors.
        #
        # Options:
        #   type:           :boolean (default). Only :boolean supported currently.
        #   filterable:     When true, the field appears in admin filter dropdowns.
        #   label:          Human-readable label for the filter dropdown header.
        #   default_scope:  Scope name for the false/absent case (default: not_<key>).
        #   filter_options: Array of [label, value] pairs for the dropdown. Values must
        #                   match scope names (e.g. "internal", "external").
        def metadata_field(key, type: :boolean, filterable: false, label: nil, default_scope: nil, filter_options: nil)
          config = {
            type: type,
            filterable: filterable,
            label: label || key.to_s.humanize,
            filter_options: filter_options
          }
          self._metadata_fields = _metadata_fields.merge(key.to_s => config)

          case type
          when :boolean
            define_boolean_metadata_field(key, default_scope: default_scope)
          end
        end

        # Returns only fields marked as filterable.
        def filterable_metadata_fields
          _metadata_fields.select { |_, config| config[:filterable] }
        end

        # Apply all filterable metadata filters from request params to a scope.
        # Only values listed in filter_options are allowed (safe from arbitrary scope calls).
        def apply_metadata_filters(scope, params)
          filterable_metadata_fields.each do |key, config|
            value = params[key.to_sym]
            next if value.blank?

            allowed = (config[:filter_options] || []).map(&:last).reject(&:blank?)
            next unless allowed.include?(value)

            scope = scope.send(value.to_sym) if scope.respond_to?(value.to_sym)
          end
          scope
        end

        # Returns true if any filterable metadata param is present.
        def metadata_filter_active?(params)
          filterable_metadata_fields.any? { |key, _| params[key.to_sym].present? }
        end

        private

        def define_boolean_metadata_field(key, default_scope: nil)
          default_scope_name = default_scope || :"not_#{key}"

          # Scope for records where key is true
          scope key, -> {
            if connection.adapter_name == "PostgreSQL"
              where("metadata @> ?", {key.to_s => true}.to_json)
            else
              where("json_extract(metadata, ?) = 1", "$.#{key}")
            end
          }

          # Scope for records where key is absent or not true
          scope default_scope_name, -> {
            if connection.adapter_name == "PostgreSQL"
              where.not("metadata @> ?", {key.to_s => true}.to_json)
            else
              where("json_extract(metadata, ?) IS NULL OR json_extract(metadata, ?) != 1", "$.#{key}", "$.#{key}")
            end
          }

          # Predicate
          define_method(:"#{key}?") { metadata_value(key.to_s) == true }

          # Reader (for form builders)
          define_method(key) { metadata_value(key.to_s) }

          # Bang methods
          define_method(:"mark_as_#{key}!") { set_metadata(key.to_s, true) }
          define_method(:"mark_as_#{default_scope_name}!") { remove_metadata(key.to_s) }

          # Virtual attribute setter — handles checkbox "1"/"0" strings
          define_method(:"#{key}=") do |value|
            cast_value = ActiveRecord::Type::Boolean.new.cast(value)
            if cast_value
              set_metadata_attribute(key.to_s, true)
            else
              self.metadata = (self[:metadata] || {}).except(key.to_s)
            end
          end
        end

        def json_cast(value)
          case value
          when true then 1
          when false then 0
          else value
          end
        end
      end

      # -- Instance methods for generic metadata access --

      def metadata_value(key)
        (self[:metadata] || {})[key.to_s]
      end

      def set_metadata(key, value)
        self.metadata = (self[:metadata] || {}).merge(key.to_s => value)
        save!
      end

      def set_metadata_attribute(key, value)
        self.metadata = (self[:metadata] || {}).merge(key.to_s => value)
      end

      def remove_metadata(key)
        self.metadata = (self[:metadata] || {}).except(key.to_s)
        save!
      end
    end
  end
end
