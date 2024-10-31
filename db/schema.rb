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

ActiveRecord::Schema[7.1].define(version: 2024_10_31_204448) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "counts", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "iban"
    t.float "initial_amount", default: 0.0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "current_amount", default: 0.0, null: false
    t.integer "ordering_number", default: 0, null: false
    t.string "monitoring_scope", default: "monthly", null: false
    t.bigint "organization_id", null: false
    t.string "count_type", default: "bank_account", null: false
    t.index ["count_type"], name: "index_counts_on_count_type"
    t.index ["current_amount"], name: "index_counts_on_current_amount"
    t.index ["initial_amount"], name: "index_counts_on_initial_amount"
    t.index ["monitoring_scope"], name: "index_counts_on_monitoring_scope"
    t.index ["name", "organization_id"], name: "index_counts_on_name_and_organization_id", unique: true
    t.index ["name"], name: "index_counts_on_name"
    t.index ["ordering_number"], name: "index_counts_on_ordering_number"
    t.index ["organization_id"], name: "index_counts_on_organization_id"
  end

  create_table "deadlines", force: :cascade do |t|
    t.string "description", null: false
    t.datetime "expired_at", null: false
    t.integer "year", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "month", null: false
    t.bigint "organization_id", null: false
    t.index ["description"], name: "index_deadlines_on_description"
    t.index ["expired_at"], name: "index_deadlines_on_expired_at"
    t.index ["month"], name: "index_deadlines_on_month"
    t.index ["organization_id"], name: "index_deadlines_on_organization_id"
    t.index ["year"], name: "index_deadlines_on_year"
  end

  create_table "expense_items", force: :cascade do |t|
    t.string "description", null: false
    t.string "color", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "organization_id", null: false
    t.index ["color", "organization_id"], name: "index_expense_items_on_color_and_organization_id", unique: true
    t.index ["color"], name: "index_expense_items_on_color"
    t.index ["description", "organization_id"], name: "index_expense_items_on_description_and_organization_id", unique: true
    t.index ["description"], name: "index_expense_items_on_description"
    t.index ["organization_id"], name: "index_expense_items_on_organization_id"
  end

  create_table "memberships", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "organization_id", null: false
    t.string "role", default: "guest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_memberships_on_organization_id"
    t.index ["role"], name: "index_memberships_on_role"
    t.index ["user_id", "organization_id"], name: "index_memberships_on_user_id_and_organization_id", unique: true
    t.index ["user_id"], name: "index_memberships_on_user_id"
  end

  create_table "movements", force: :cascade do |t|
    t.bigint "count_id", null: false
    t.bigint "expense_item_id"
    t.float "amount", null: false
    t.string "causal", null: false
    t.string "movement_type", null: false
    t.datetime "emitted_at", null: false
    t.integer "year", null: false
    t.integer "month", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "year_month_day", null: false
    t.integer "day", null: false
    t.index ["amount"], name: "index_movements_on_amount"
    t.index ["count_id"], name: "index_movements_on_count_id"
    t.index ["day"], name: "index_movements_on_day"
    t.index ["emitted_at"], name: "index_movements_on_emitted_at"
    t.index ["expense_item_id"], name: "index_movements_on_expense_item_id"
    t.index ["month"], name: "index_movements_on_month"
    t.index ["movement_type"], name: "index_movements_on_movement_type"
    t.index ["year"], name: "index_movements_on_year"
    t.index ["year_month_day"], name: "index_movements_on_year_month_day"
  end

  create_table "organizations", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_organizations_on_name", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "role"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["first_name"], name: "index_users_on_first_name"
    t.index ["last_name"], name: "index_users_on_last_name"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "counts", "organizations"
  add_foreign_key "deadlines", "organizations"
  add_foreign_key "expense_items", "organizations"
  add_foreign_key "memberships", "organizations"
  add_foreign_key "memberships", "users"
  add_foreign_key "movements", "counts"
  add_foreign_key "movements", "expense_items"
end
