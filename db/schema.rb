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

ActiveRecord::Schema[8.1].define(version: 2026_02_02_223013) do
  create_table "candidates", force: :cascade do |t|
    t.string "birth_date"
    t.datetime "created_at", null: false
    t.string "department"
    t.string "district"
    t.string "document_number", null: false
    t.string "document_type"
    t.string "electoral_file_code"
    t.string "first_name"
    t.string "gender"
    t.string "is_native"
    t.string "maternal_surname"
    t.string "paternal_surname"
    t.string "photo_filename"
    t.string "photo_guid"
    t.integer "political_organization_id", null: false
    t.integer "position_number"
    t.string "position_type", null: false
    t.string "province"
    t.string "status"
    t.datetime "updated_at", null: false
    t.index ["department"], name: "index_candidates_on_department"
    t.index ["document_number"], name: "index_candidates_on_document_number"
    t.index ["political_organization_id"], name: "index_candidates_on_political_organization_id"
    t.index ["position_type"], name: "index_candidates_on_position_type"
    t.index ["status"], name: "index_candidates_on_status"
  end

  create_table "political_organizations", force: :cascade do |t|
    t.string "acronym"
    t.text "address"
    t.string "cancellation_date"
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.string "logo_url"
    t.string "name", null: false
    t.string "organization_type"
    t.string "registration_date"
    t.string "status"
    t.datetime "updated_at", null: false
    t.string "website"
    t.index ["code"], name: "index_political_organizations_on_code", unique: true
    t.index ["name"], name: "index_political_organizations_on_name"
    t.index ["status"], name: "index_political_organizations_on_status"
  end

  add_foreign_key "candidates", "political_organizations"
end
