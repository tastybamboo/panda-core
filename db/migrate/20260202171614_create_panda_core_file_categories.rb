# frozen_string_literal: true

class CreatePandaCoreFileCategories < ActiveRecord::Migration[7.1]
  def change
    create_table :panda_core_file_categories, id: :uuid do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.references :parent, type: :uuid, foreign_key: {to_table: :panda_core_file_categories}
      t.boolean :system, null: false, default: false
      t.string :icon
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    add_index :panda_core_file_categories, :slug, unique: true
    add_index :panda_core_file_categories, :position

    create_table :panda_core_file_categorizations, id: :uuid do |t|
      t.references :file_category, null: false, type: :uuid,
        foreign_key: {to_table: :panda_core_file_categories}
      t.column :blob_id, active_storage_blob_key_type, null: false
      t.timestamps
    end

    add_index :panda_core_file_categorizations, %i[file_category_id blob_id],
      unique: true, name: :idx_file_categorizations_on_category_and_blob
    add_index :panda_core_file_categorizations, :blob_id
    add_foreign_key :panda_core_file_categorizations, :active_storage_blobs, column: :blob_id
  end

  private

  # The type of active_storage_blobs.id is decided by the *host application*, not
  # by this gem: Rails' own CreateActiveStorageTables reads
  # Rails.configuration.generators[:active_record][:primary_key_type] at migration
  # time, so an app that sets `primary_key_type: :uuid` gets uuid blob ids while an
  # app that leaves it alone gets bigint.
  #
  # Hardcoding either one makes this migration fail on half of all host apps, and
  # makes `db:migrate` and `db:schema:load` build structurally different databases
  # in the same app. Read the type that is actually there instead.
  def active_storage_blob_key_type
    unless table_exists?(:active_storage_blobs)
      raise <<~MESSAGE
        panda-core's file categorisation tables reference active_storage_blobs, but that
        table does not exist yet. Install and run Active Storage's migrations first:

          bin/rails active_storage:install
          bin/rails db:migrate
      MESSAGE
    end

    column = columns(:active_storage_blobs).find { |c| c.name == "id" }

    case column.type
    when :integer
      # PostgreSQL bigserial reports limit 8; SQLite's INTEGER primary key reports
      # no limit and is 64-bit. Only a genuinely narrow integer stays :integer.
      (column.limit && column.limit < 8) ? :integer : :bigint
    else
      column.type
    end
  end
end
