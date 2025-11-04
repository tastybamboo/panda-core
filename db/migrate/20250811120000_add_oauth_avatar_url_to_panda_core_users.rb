# frozen_string_literal: true

class AddOauthAvatarUrlToPandaCoreUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :panda_core_users, :oauth_avatar_url, :string
  end
end
