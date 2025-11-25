# frozen_string_literal: true

class CreatePandaCoreUsers < ActiveRecord::Migration[7.1]
  def change
    # Enable pgcrypto extension for PostgreSQL UUID generation
    enable_extension "pgcrypto" if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"

    # Rails 7.1+ supports id: :uuid across databases
    # PostgreSQL uses gen_random_uuid(), SQLite uses application-generated UUIDs
    create_table :panda_core_users, id: :uuid do |t|
      t.string :name
      t.string :email, null: false
      t.string :image_url
      t.boolean :admin, default: false, null: false
      t.string :current_theme
      t.string :oauth_avatar_url
      t.timestamps
    end

    add_index :panda_core_users, :email, unique: true
  end
end
