# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_02_17_000001) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "action_mailbox_inbound_emails", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "message_checksum", null: false
    t.string "message_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["message_id", "message_checksum"], name: "index_action_mailbox_inbound_emails_uniqueness", unique: true
  end

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "panda_core_feature_flags", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description"
    t.boolean "enabled", default: false, null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_panda_core_feature_flags_on_key", unique: true
  end

  create_table "panda_core_file_categories", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "icon"
    t.string "name", null: false
    t.uuid "parent_id"
    t.integer "position", default: 0, null: false
    t.string "slug", null: false
    t.boolean "system", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["parent_id"], name: "index_panda_core_file_categories_on_parent_id"
    t.index ["position"], name: "index_panda_core_file_categories_on_position"
    t.index ["slug"], name: "index_panda_core_file_categories_on_slug", unique: true
  end

  create_table "panda_core_file_categorizations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.uuid "file_category_id", null: false
    t.datetime "updated_at", null: false
    t.index ["blob_id"], name: "index_panda_core_file_categorizations_on_blob_id"
    t.index ["file_category_id", "blob_id"], name: "idx_file_categorizations_on_category_and_blob", unique: true
    t.index ["file_category_id"], name: "index_panda_core_file_categorizations_on_file_category_id"
  end

  create_table "panda_core_presences", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "last_seen_at", null: false
    t.uuid "presenceable_id", null: false
    t.string "presenceable_type", null: false
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["last_seen_at"], name: "index_panda_core_presences_on_last_seen_at"
    t.index ["presenceable_type", "presenceable_id", "user_id"], name: "index_unique_presence", unique: true
    t.index ["presenceable_type", "presenceable_id"], name: "index_presences_on_presenceable"
    t.index ["user_id"], name: "index_panda_core_presences_on_user_id"
  end

  create_table "panda_core_user_activities", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "action", null: false
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.jsonb "metadata", default: {}
    t.uuid "resource_id"
    t.string "resource_type"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.uuid "user_id", null: false
    t.index ["action"], name: "index_panda_core_user_activities_on_action"
    t.index ["created_at"], name: "index_panda_core_user_activities_on_created_at"
    t.index ["resource_type", "resource_id"], name: "idx_on_resource_type_resource_id_fe067c2837"
    t.index ["user_id"], name: "index_panda_core_user_activities_on_user_id"
  end

  create_table "panda_core_user_sessions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "last_active_at"
    t.datetime "revoked_at"
    t.uuid "revoked_by_id"
    t.string "session_id", null: false
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.uuid "user_id", null: false
    t.index ["active"], name: "index_panda_core_user_sessions_on_active"
    t.index ["session_id"], name: "index_panda_core_user_sessions_on_session_id", unique: true
    t.index ["user_id"], name: "index_panda_core_user_sessions_on_user_id"
  end

  create_table "panda_core_users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.datetime "created_at", null: false
    t.string "current_theme"
    t.string "email", null: false
    t.boolean "enabled", default: true, null: false
    t.string "image_url"
    t.datetime "invitation_accepted_at"
    t.datetime "invitation_sent_at"
    t.string "invitation_token"
    t.uuid "invited_by_id"
    t.datetime "last_login_at"
    t.string "last_login_ip"
    t.integer "login_count", default: 0, null: false
    t.string "name"
    t.string "oauth_avatar_url"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_panda_core_users_on_email", unique: true
    t.index ["enabled"], name: "index_panda_core_users_on_enabled"
    t.index ["invitation_token"], name: "index_panda_core_users_on_invitation_token", unique: true
    t.index ["invited_by_id"], name: "index_panda_core_users_on_invited_by_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "panda_core_file_categories", "panda_core_file_categories", column: "parent_id"
  add_foreign_key "panda_core_file_categorizations", "active_storage_blobs", column: "blob_id"
  add_foreign_key "panda_core_file_categorizations", "panda_core_file_categories", column: "file_category_id"
  add_foreign_key "panda_core_presences", "panda_core_users", column: "user_id"
  add_foreign_key "panda_core_user_activities", "panda_core_users", column: "user_id"
  add_foreign_key "panda_core_user_sessions", "panda_core_users", column: "revoked_by_id", on_delete: :nullify
  add_foreign_key "panda_core_user_sessions", "panda_core_users", column: "user_id"
  add_foreign_key "panda_core_users", "panda_core_users", column: "invited_by_id"
end
