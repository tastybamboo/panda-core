# frozen_string_literal: true

module Panda
  module Core
    module Admin
      class ImportSessionsController < BaseController
        before_action :set_initial_breadcrumb
        before_action :set_import_session, only: %i[show column_map update_mapping preview import]

        def index
          @import_sessions = scoped_import_sessions.recent
          @import_sessions = @import_sessions.where(importable_type: params[:type]) if params[:type].present?
        end

        def new
          @importable_type = params[:importable_type]
        end

        def create
          tenant = resolve_tenant
          uploaded_file = params[:import_file]

          unless uploaded_file.present?
            @importable_type = params[:importable_type]
            flash.now[:error] = "Please select a file to upload."
            render :new, status: :unprocessable_entity
            return
          end

          if FileParser.xls?(uploaded_file.original_filename)
            @importable_type = params[:importable_type]
            flash.now[:error] = "XLS format is not supported. Please save your spreadsheet as XLSX, CSV, or TSV and try again."
            render :new, status: :unprocessable_entity
            return
          end

          unless FileParser.supported?(uploaded_file.original_filename)
            @importable_type = params[:importable_type]
            flash.now[:error] = "Unsupported file format. Please upload a CSV, TSV, or XLSX file."
            render :new, status: :unprocessable_entity
            return
          end

          @import_session = ImportSession.new(
            importable_type: params[:importable_type],
            user: current_user,
            tenant: tenant,
            status: "mapping"
          )

          if uploaded_file.present?
            @import_session.import_file.attach(uploaded_file)
          end

          if @import_session.save
            redirect_to column_map_admin_import_session_path(@import_session)
          else
            @importable_type = params[:importable_type]
            render :new, status: :unprocessable_entity
          end
        end

        def show
        end

        def column_map
          @headers = @import_session.file_headers
          @field_options = @import_session.column_options
        end

        def update_mapping
          mapping = {}
          (params[:mapping] || {}).each do |csv_col, field_name|
            mapping[csv_col] = field_name if field_name.present?
          end

          @import_session.update!(column_mapping: mapping, status: "previewing")
          redirect_to preview_admin_import_session_path(@import_session)
        end

        def preview
          @preview_rows = @import_session.preview_rows(limit: 5)
          @mapping = @import_session.column_mapping
          @field_definitions = @import_session.column_options
        end

        def import
          @import_session.update!(status: "importing")

          # Run synchronously for now — swap to CSVImportJob.perform_later for async
          CSVImportService.new(@import_session).call

          redirect_to admin_import_session_path(@import_session), success: "Import complete."
        rescue => e
          redirect_to admin_import_session_path(@import_session), error: "Import failed: #{e.message}"
        end

        private

        def set_import_session
          @import_session = scoped_import_sessions.find(params[:id])
        end

        def set_initial_breadcrumb
          add_breadcrumb "Import", admin_import_sessions_path
        end

        def scoped_import_sessions
          tenant = resolve_tenant
          tenant ? ImportSession.where(tenant: tenant) : ImportSession.where(tenant_type: nil)
        end

        def resolve_tenant
          return ActsAsTenant.current_tenant if defined?(ActsAsTenant) && ActsAsTenant.current_tenant
          nil
        end
      end
    end
  end
end
