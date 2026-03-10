# frozen_string_literal: true

module Panda
  module Core
    class ImportSession < ApplicationRecord
      self.table_name = "panda_core_import_sessions"

      STATUSES = %w[pending mapping previewing importing complete failed].freeze

      belongs_to :user, class_name: "Panda::Core::User"
      belongs_to :tenant, polymorphic: true, optional: true
      has_one_attached :import_file

      validates :importable_type, presence: true
      validates :status, inclusion: {in: STATUSES}
      validate :importable_type_must_be_importable

      scope :recent, -> { order(created_at: :desc) }

      def importable_class
        klass = importable_type.safe_constantize
        raise ArgumentError, "Unknown importable type: #{importable_type}" unless klass
        raise ArgumentError, "#{importable_type} is not importable" unless klass.include?(Panda::Core::Importable)
        klass
      end

      def file_parser
        return nil unless import_file.attached?
        @file_parser ||= FileParser.new(import_file.filename.to_s, import_file.download)
      end

      def file_headers
        file_parser&.headers || []
      end

      def file_rows
        file_parser&.rows || []
      end

      def preview_rows(limit: 5)
        file_rows.first(limit)
      end

      def column_options
        return [] unless importable_class.respond_to?(:import_field_definitions)
        importable_class.import_field_definitions
      end

      def progress_percentage
        return 0 if total_rows.zero?
        ((processed_rows.to_f / total_rows) * 100).round
      end

      def complete?
        status == "complete"
      end

      def importing?
        status == "importing"
      end

      def failed?
        status == "failed"
      end

      private

      def importable_type_must_be_importable
        return if importable_type.blank?
        klass = importable_type.safe_constantize
        if klass.nil?
          errors.add(:importable_type, "is not a valid class")
        elsif !klass.include?(Panda::Core::Importable)
          errors.add(:importable_type, "is not importable")
        end
      end
    end
  end
end
