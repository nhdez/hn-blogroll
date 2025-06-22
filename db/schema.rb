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

ActiveRecord::Schema[7.0].define(version: 2025_06_22_011535) do
  create_table "blogs", force: :cascade do |t|
    t.string "username"
    t.text "description"
    t.string "hyperlink"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "karma"
    t.string "rss"
    t.string "last_post_title"
    t.string "last_post_url"
    t.string "last_post_date"
    t.boolean "is_approved", default: false
    t.boolean "is_online"
    t.datetime "online_last_check"
    t.datetime "submitted_at"
    t.text "rejection_reason"
    t.text "admin_notes"
    t.string "submitter_email"
    t.string "submitter_name"
    t.string "approval_status", default: "pending"
    t.datetime "reviewed_at"
    t.string "reviewed_by"
    t.index ["approval_status"], name: "index_blogs_on_approval_status"
    t.index ["submitted_at"], name: "index_blogs_on_submitted_at"
  end

  create_table "posts", force: :cascade do |t|
    t.integer "blog_id", null: false
    t.string "title", null: false
    t.string "url", null: false
    t.text "content"
    t.text "summary"
    t.datetime "published_at"
    t.string "guid"
    t.string "unique_key", null: false
    t.integer "word_count"
    t.string "author"
    t.json "tags", default: []
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["blog_id", "published_at"], name: "index_posts_on_blog_id_and_published_at"
    t.index ["blog_id"], name: "index_posts_on_blog_id"
    t.index ["published_at"], name: "index_posts_on_published_at"
    t.index ["unique_key"], name: "index_posts_on_unique_key", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.boolean "admin", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "posts", "blogs"
end
