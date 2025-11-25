# frozen_string_literal: true

class RenameIsAdminToAdmin < ActiveRecord::Migration[7.1]
  def up
    return if column_exists?(:panda_core_users, :admin)
    return unless column_exists?(:panda_core_users, :is_admin)

    rename_column :panda_core_users, :is_admin, :admin
  end

  def down
    return if column_exists?(:panda_core_users, :is_admin)
    return unless column_exists?(:panda_core_users, :admin)

    rename_column :panda_core_users, :admin, :is_admin
  end
end
