# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20170321003511) do

  create_table "discussions", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "todo_id"
    t.text     "content"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["deleted_at"], name: "index_discussions_on_deleted_at"
    t.index ["todo_id"], name: "index_discussions_on_todo_id"
    t.index ["user_id"], name: "index_discussions_on_user_id"
  end

  create_table "friendships", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "friend_id"
    t.string   "nickname"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["deleted_at"], name: "index_friendships_on_deleted_at"
    t.index ["friend_id"], name: "index_friendships_on_friend_id"
    t.index ["user_id"], name: "index_friendships_on_user_id"
  end

  create_table "groups", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "name"
    t.string   "friends_id"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["deleted_at"], name: "index_groups_on_deleted_at"
    t.index ["user_id"], name: "index_groups_on_user_id"
  end

  create_table "grouptodos", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "group_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text     "content"
    t.datetime "deleted_at"
    t.boolean  "is_finish"
    t.index ["deleted_at"], name: "index_grouptodos_on_deleted_at"
    t.index ["group_id"], name: "index_grouptodos_on_group_id"
    t.index ["user_id"], name: "index_grouptodos_on_user_id"
  end

  create_table "payments", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "openid"
    t.string   "transaction_id"
    t.integer  "total_fee"
    t.string   "time_end"
    t.string   "result_code"
    t.datetime "deleted_at"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.index ["deleted_at"], name: "index_payments_on_deleted_at"
    t.index ["openid"], name: "index_payments_on_openid"
    t.index ["user_id"], name: "index_payments_on_user_id"
  end

  create_table "todos", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "receiver_id"
    t.text     "content"
    t.datetime "deleted_at"
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
    t.integer  "grouptodo_id"
    t.boolean  "is_finish"
    t.integer  "discussions_count", default: 0
    t.index ["deleted_at"], name: "index_todos_on_deleted_at"
    t.index ["grouptodo_id"], name: "index_todos_on_grouptodo_id"
    t.index ["user_id"], name: "index_todos_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string   "openid"
    t.string   "nickname"
    t.datetime "end_time"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["deleted_at"], name: "index_users_on_deleted_at"
    t.index ["end_time"], name: "index_users_on_end_time"
    t.index ["openid"], name: "index_users_on_openid"
  end

end
