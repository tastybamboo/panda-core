# frozen_string_literal: true

class AddCurrentThemeToPandaCoreUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :panda_core_users, :current_theme, :string unless column_exists?(:panda_core_users, :current_theme)
  end
end
