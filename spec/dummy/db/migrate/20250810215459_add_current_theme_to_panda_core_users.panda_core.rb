# frozen_string_literal: true

# This migration comes from panda_core (originally 20241210000003)
class AddCurrentThemeToPandaCoreUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :panda_core_users, :current_theme, :string, default: "default"
  end
end
