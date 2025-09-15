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

ActiveRecord::Schema[8.0].define(version: 2025_09_15_035205) do
  create_table "cable_types", force: :cascade do |t|
    t.string "conductor_material"
    t.string "conductor_makeup"
    t.float "csa"
    t.float "neutral_csa"
    t.float "earth_csa"
    t.string "insulation"
    t.string "bedding"
    t.string "armour"
    t.string "sheath"
    t.decimal "bedding_od", precision: 3, scale: 1
    t.decimal "overall_od", precision: 3, scale: 1
    t.integer "temperature_rating"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "unique_spec"
    t.text "description", default: "", null: false
    t.integer "project_id", null: false
    t.index ["project_id"], name: "index_cable_types_on_project_id"
    t.index ["unique_spec"], name: "index_cable_types_on_unique_spec", unique: true
  end

  create_table "cables", force: :cascade do |t|
    t.integer "cable_type_id", null: false
    t.integer "circuit_id"
    t.decimal "route_length", precision: 4, scale: 1
    t.decimal "vertical_allowance", precision: 3, scale: 1
    t.decimal "termination_allowance", precision: 3, scale: 1
    t.integer "start_mark"
    t.integer "end_mark"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cable_type_id"], name: "index_cables_on_cable_type_id"
    t.index ["circuit_id"], name: "index_cables_on_circuit_id"
  end

  create_table "circuits", force: :cascade do |t|
    t.integer "switchboard_id", null: false
    t.integer "serial"
    t.integer "phase"
    t.integer "device"
    t.integer "poles"
    t.integer "curve"
    t.float "rating"
    t.integer "elcb"
    t.boolean "contactor"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["switchboard_id", "serial"], name: "index_circuits_on_switchboard_id_and_serial", unique: true
    t.index ["switchboard_id"], name: "index_circuits_on_switchboard_id"
  end

  create_table "demands", force: :cascade do |t|
    t.string "demandable_type", null: false
    t.integer "demandable_id", null: false
    t.integer "circuit_id"
    t.integer "basis"
    t.string "basis_notes"
    t.float "supply"
    t.integer "config"
    t.float "power"
    t.float "vector"
    t.float "power_factor"
    t.float "current"
    t.float "duty"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["circuit_id"], name: "index_demands_on_circuit_id"
    t.index ["demandable_type", "demandable_id"], name: "index_demands_on_demandable"
  end

  create_table "disciplines", force: :cascade do |t|
    t.string "code"
    t.string "name"
  end

  create_table "light_ccts", force: :cascade do |t|
    t.string "light_fitting_type"
    t.integer "quantity"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "motors", force: :cascade do |t|
    t.string "motor_type"
    t.string "frame_size"
    t.integer "poles"
    t.string "ingress_protection"
    t.float "speed_rated"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "projects", force: :cascade do |t|
    t.string "code"
    t.string "title"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "roles", force: :cascade do |t|
    t.string "name"
    t.string "resource_type"
    t.integer "resource_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name", "resource_type", "resource_id"], name: "index_roles_on_name_and_resource_type_and_resource_id"
    t.index ["name"], name: "index_roles_on_name"
    t.index ["resource_type", "resource_id"], name: "index_roles_on_resource"
  end

  create_table "socket_ccts", force: :cascade do |t|
    t.string "socket_type"
    t.integer "quantity"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "switchboards", force: :cascade do |t|
    t.string "location"
    t.string "ingress_protection"
    t.float "busbar_rating"
    t.float "busbar_fault_rating"
    t.float "busbar_fault_duration"
    t.string "cable_entry"
    t.text "incomer_protection"
    t.text "metering"
    t.text "neutral_bar_connections"
    t.text "earth_bar_connections"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tags", force: :cascade do |t|
    t.integer "discipline_id", null: false
    t.string "prefix"
    t.integer "serial"
    t.string "suffix", default: ""
    t.string "service"
    t.text "notes"
    t.integer "project_id", null: false
    t.integer "stage"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "tagable_type"
    t.integer "tagable_id"
    t.string "loop_id", null: false
    t.index ["discipline_id"], name: "index_tags_on_discipline_id"
    t.index ["loop_id"], name: "index_tags_on_loop_id"
    t.index ["project_id", "discipline_id", "prefix", "serial", "suffix"], name: "index_tags_on_project_and_full_tag", unique: true
    t.index ["project_id"], name: "index_tags_on_project_id"
    t.index ["tagable_type", "tagable_id"], name: "index_tags_on_tagable"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", default: "", null: false
    t.boolean "admin", default: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  create_table "users_roles", id: false, force: :cascade do |t|
    t.integer "user_id"
    t.integer "role_id"
    t.index ["role_id"], name: "index_users_roles_on_role_id"
    t.index ["user_id", "role_id"], name: "index_users_roles_on_user_id_and_role_id"
    t.index ["user_id"], name: "index_users_roles_on_user_id"
  end

  add_foreign_key "cable_types", "projects"
  add_foreign_key "cables", "cable_types"
  add_foreign_key "cables", "circuits"
  add_foreign_key "circuits", "switchboards"
  add_foreign_key "demands", "circuits"
  add_foreign_key "tags", "disciplines"
  add_foreign_key "tags", "projects"
end
