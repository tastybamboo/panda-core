# frozen_string_literal: true

class FixActiveStorageAttachmentsRecordIdType < ActiveRecord::Migration[8.1]
  def up
    return unless table_exists?(:active_storage_attachments)

    column = columns(:active_storage_attachments).find { |c| c.name == "record_id" }
    return if column.nil? || column.type == :string

    # Remove orphaned attachments where a UUID was silently cast to 0. This only
    # ever happened on an integer column: on a uuid record_id (a host app with
    # `primary_key_type: :uuid`) the comparison is not even well typed.
    if column.type == :integer
      execute <<~SQL
        DELETE FROM active_storage_attachments WHERE record_id = 0
      SQL
    end

    # Drop the unique index before changing the column type
    remove_index :active_storage_attachments,
      name: "index_active_storage_attachments_uniqueness",
      if_exists: true

    change_column :active_storage_attachments, :record_id, :string,
      null: false,
      **cast_to_string_options

    add_index :active_storage_attachments,
      [:record_type, :record_id, :name, :blob_id],
      unique: true,
      name: "index_active_storage_attachments_uniqueness"
  end

  def down
    return unless table_exists?(:active_storage_attachments)

    remove_index :active_storage_attachments,
      name: "index_active_storage_attachments_uniqueness",
      if_exists: true

    change_column :active_storage_attachments, :record_id, :bigint,
      null: false,
      using: "record_id::bigint"

    add_index :active_storage_attachments,
      [:record_type, :record_id, :name, :blob_id],
      unique: true,
      name: "index_active_storage_attachments_uniqueness"
  end

  private

  # PostgreSQL has no assignment cast from uuid to text, so ALTER TABLE needs an
  # explicit USING clause when the host app created record_id as a uuid. Other
  # adapters (and integer columns) neither need nor accept one.
  def cast_to_string_options
    return {} unless adapter_is_postgresql?

    {using: "record_id::text"}
  end

  def adapter_is_postgresql?
    connection.adapter_name.match?(/postgres/i)
  end
end
