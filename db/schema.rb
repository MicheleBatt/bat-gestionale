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

ActiveRecord::Schema[7.1].define(version: 2024_10_21_144249) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "counts", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.string "iban"
    t.float "initial_amount", default: 0.0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_counts_on_name", unique: true
  end

  create_table "deadlines", force: :cascade do |t|
    t.string "description", null: false
    t.datetime "expired_at", null: false
    t.integer "year", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "month", null: false
    t.index ["description"], name: "index_deadlines_on_description"
    t.index ["expired_at"], name: "index_deadlines_on_expired_at"
    t.index ["month"], name: "index_deadlines_on_month"
    t.index ["year", "description"], name: "index_deadlines_on_year_and_description", unique: true
    t.index ["year"], name: "index_deadlines_on_year"
  end

  create_table "expense_items", force: :cascade do |t|
    t.string "description", null: false
    t.string "color", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["color"], name: "index_expense_items_on_color", unique: true
    t.index ["description"], name: "index_expense_items_on_description", unique: true
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
    t.index ["count_id"], name: "index_movements_on_count_id"
    t.index ["emitted_at"], name: "index_movements_on_emitted_at"
    t.index ["expense_item_id"], name: "index_movements_on_expense_item_id"
    t.index ["month"], name: "index_movements_on_month"
    t.index ["movement_type"], name: "index_movements_on_movement_type"
    t.index ["year"], name: "index_movements_on_year"
  end

  add_foreign_key "movements", "counts"
  add_foreign_key "movements", "expense_items"
end
