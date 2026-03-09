# frozen_string_literal: true

require "csv"

module Panda
  module Core
    class CsvImportService
      attr_reader :import_session

      def initialize(import_session)
        @import_session = import_session
      end

      def call
        import_session.update!(status: "importing", started_at: Time.current)
        rows = import_session.csv_rows
        import_session.update!(total_rows: rows.size)

        klass = import_session.importable_class
        mapping = import_session.column_mapping
        tenant_attrs = build_tenant_attrs

        rows.each_with_index do |row, index|
          process_row(klass, row, mapping, tenant_attrs, index + 2) # +2 for header + 1-based
        end

        import_session.update!(status: "complete", completed_at: Time.current)
      rescue => e
        import_session.update!(status: "failed", completed_at: Time.current)
        Rails.logger.error("[CsvImportService] Import #{import_session.id} failed: #{e.message}")
        raise
      end

      private

      def process_row(klass, row, mapping, tenant_attrs, row_number)
        attrs, parse_errors = klass.import_row(row, mapping)

        if parse_errors.any?
          log_error(row_number, parse_errors)
          import_session.increment!(:error_count)
        else
          record = klass.new(attrs.merge(tenant_attrs))
          if record.save
            import_session.increment!(:imported_count)
          else
            log_error(row_number, record.errors.full_messages)
            import_session.increment!(:error_count)
          end
        end

        import_session.increment!(:processed_rows)
      end

      def log_error(row_number, errors)
        log = import_session.errors_log || []
        log << {row: row_number, errors: errors}
        import_session.update_column(:errors_log, log)
      end

      def build_tenant_attrs
        return {} unless import_session.tenant_id
        {tenant_id: import_session.tenant_id}
      end
    end
  end
end
