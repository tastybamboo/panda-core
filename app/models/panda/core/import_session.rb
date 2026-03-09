# frozen_string_literal: true

require "csv"

module Panda
  module Core
    class ImportSession < ApplicationRecord
      self.table_name = "panda_core_import_sessions"

      STATUSES = %w[pending mapping previewing importing complete failed].freeze

      belongs_to :user, class_name: "Panda::Core::User"
      belongs_to :tenant, polymorphic: true, optional: true
      has_one_attached :csv_file

      validates :importable_type, presence: true
      validates :status, inclusion: {in: STATUSES}

      scope :recent, -> { order(created_at: :desc) }

      def importable_class
        importable_type.constantize
      end

      def csv_headers
        return [] unless csv_file.attached?
        row = CSV.parse(csv_file.download, headers: false).first
        row || []
      end

      def csv_rows
        return [] unless csv_file.attached?
        CSV.parse(csv_file.download, headers: true)
      end

      def preview_rows(limit: 5)
        csv_rows.first(limit)
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
    end
  end
end
