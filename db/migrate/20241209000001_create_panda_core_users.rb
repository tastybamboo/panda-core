# frozen_string_literal: true

class CreatePandaCoreUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :panda_core_users, id: :uuid do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :image_url
      t.boolean :is_admin, default: false, null: false
      t.timestamps
    end

    add_index :panda_core_users, :email, unique: true
  end
end
