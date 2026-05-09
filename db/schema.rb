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

ActiveRecord::Schema[8.0].define(version: 2026_05_05_105807) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "disciplines", force: :cascade do |t|
    t.string "name"
    t.bigint "project_id", null: false
    t.jsonb "prefix_schema"
    t.string "label", comment: "Short 2-3 character code for display"
    t.integer "sort_order", default: 100, comment: "Display order in UI (lower numbers first)"
    t.text "notes"
    t.bigint "swatch_id"
    t.string "required_role"
    t.index ["project_id", "label"], name: "index_disciplines_on_project_id_and_label", unique: true
    t.index ["project_id", "name"], name: "index_disciplines_on_project_id_and_name", unique: true
    t.index ["project_id"], name: "index_disciplines_on_project_id"
    t.index ["sort_order"], name: "index_disciplines_on_sort_order"
    t.index ["swatch_id"], name: "index_disciplines_on_swatch_id"
  end

  create_table "doc_types", force: :cascade do |t|
    t.bigint "discipline_id"
    t.string "code", null: false
    t.string "name", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["discipline_id", "code"], name: "index_doc_types_on_discipline_id_and_code", unique: true
    t.index ["discipline_id"], name: "index_doc_types_on_discipline_id"
  end

  create_table "documents", force: :cascade do |t|
    t.bigint "discipline_id"
    t.bigint "doc_type_id"
    t.integer "serial"
    t.string "title", null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "doc_number"
    t.index ["discipline_id"], name: "index_documents_on_discipline_id"
    t.index ["doc_number"], name: "index_documents_on_doc_number", unique: true
    t.index ["doc_type_id"], name: "index_documents_on_doc_type_id"
    t.index ["serial", "discipline_id", "doc_type_id"], name: "index_documents_on_serial_and_discipline_id_and_doc_type_id", unique: true
  end

  create_table "electrical_cable_types", force: :cascade do |t|
    t.integer "conductor_material"
    t.float "csa"
    t.float "neutral_csa"
    t.float "earth_csa"
    t.integer "insulation"
    t.integer "bedding"
    t.integer "armour"
    t.integer "sheath"
    t.decimal "bedding_od", precision: 3, scale: 1
    t.decimal "overall_od", precision: 3, scale: 1
    t.integer "temperature_rating"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "code"
    t.text "notes", default: "", null: false
    t.integer "groups"
    t.integer "voltage_rating"
    t.integer "construction"
    t.bigint "discipline_id", null: false
    t.index ["discipline_id"], name: "index_electrical_cable_types_on_discipline_id"
  end

  create_table "electrical_cables", force: :cascade do |t|
    t.integer "electrical_cable_type_id", null: false
    t.decimal "route_length", precision: 4, scale: 1
    t.decimal "vertical_allowance", precision: 3, scale: 1
    t.decimal "termination_allowance", precision: 3, scale: 1
    t.integer "start_mark"
    t.integer "end_mark"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "from_type"
    t.integer "from_id"
    t.string "to_type"
    t.integer "to_id"
    t.text "notes"
    t.index ["electrical_cable_type_id"], name: "index_electrical_cables_on_electrical_cable_type_id"
    t.index ["from_type", "from_id"], name: "index_electrical_cables_on_from"
    t.index ["to_type", "to_id"], name: "index_electrical_cables_on_to"
  end

  create_table "electrical_circuits", force: :cascade do |t|
    t.integer "electrical_switchboard_id", null: false
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
    t.index ["electrical_switchboard_id", "serial"], name: "index_electrical_circuits_on_switchboard_id_and_serial", unique: true
    t.index ["electrical_switchboard_id"], name: "index_electrical_circuits_on_electrical_switchboard_id"
  end

  create_table "electrical_demands", force: :cascade do |t|
    t.integer "demandable_id", null: false
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
    t.text "notes"
    t.string "demandable_type"
    t.index ["demandable_type", "demandable_id"], name: "index_electrical_demands_on_demandable"
  end

  create_table "electrical_heaters", force: :cascade do |t|
    t.integer "heater_type", null: false
    t.integer "application", null: false
    t.string "ingress_protection"
    t.float "sheath_temperature_max"
    t.float "power_density_min"
    t.float "power_density_max"
    t.integer "sheath_material"
    t.integer "insulation_material"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "notes"
  end

  create_table "electrical_light_ccts", force: :cascade do |t|
    t.integer "light_fitting_type"
    t.integer "quantity"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "notes"
  end

  create_table "electrical_motors", force: :cascade do |t|
    t.integer "motor_type"
    t.integer "frame_size"
    t.integer "poles"
    t.string "ingress_protection"
    t.float "speed_rated"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "notes"
  end

  create_table "electrical_socket_ccts", force: :cascade do |t|
    t.integer "socket_type"
    t.integer "quantity"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "notes"
  end

  create_table "electrical_switchboards", force: :cascade do |t|
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
    t.integer "voltage_rating"
    t.string "ingress_protection"
    t.text "notes"
  end

  create_table "issues", force: :cascade do |t|
    t.bigint "document_id", null: false
    t.string "code", null: false
    t.string "reason", null: false
    t.bigint "source_format_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["document_id", "code"], name: "index_issues_on_document_id_and_code", unique: true
    t.index ["document_id"], name: "index_issues_on_document_id"
    t.index ["source_format_id"], name: "index_issues_on_source_format_id"
  end

  create_table "project_change_requests", force: :cascade do |t|
    t.bigint "project_id", null: false
    t.integer "serial"
    t.text "reason", null: false
    t.text "summary", null: false
    t.integer "duration", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "title", null: false
    t.index ["project_id", "serial"], name: "index_project_change_requests_on_project_id_and_serial", unique: true
    t.index ["project_id"], name: "index_project_change_requests_on_project_id"
    t.index ["title", "project_id"], name: "index_project_change_requests_on_title_and_project_id", unique: true
  end

  create_table "projects", force: :cascade do |t|
    t.string "code"
    t.string "title"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "swatch_id"
    t.index ["swatch_id"], name: "index_projects_on_swatch_id"
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

  create_table "source_formats", force: :cascade do |t|
    t.string "title", null: false
    t.string "file_extension"
    t.string "revision"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "vendor"
    t.index ["revision", "title"], name: "index_source_formats_on_revision_and_title", unique: true
  end

  create_table "swatches", force: :cascade do |t|
    t.string "name", null: false
    t.string "bg", null: false
    t.string "text", null: false
    t.string "form_bg", null: false
    t.string "form_field", null: false
    t.string "card_bg", null: false
    t.string "card_header_bg", null: false
    t.string "card_border", null: false
    t.string "badge_bg", null: false
    t.string "badge_text", null: false
    t.string "link_text", null: false
    t.string "link_hover", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_swatches_on_name", unique: true
  end

  create_table "tags", force: :cascade do |t|
    t.integer "discipline_id", null: false
    t.string "prefix"
    t.integer "serial"
    t.string "suffix", default: ""
    t.string "service"
    t.text "notes"
    t.integer "stage"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "tagable_type"
    t.integer "tagable_id"
    t.string "location"
    t.virtual "full_tag", type: :string, as: "(((COALESCE(prefix, ''::character varying))::text || lpad((serial)::text, 4, '0'::text)) || (COALESCE(suffix, ''::character varying))::text)", stored: true
    t.virtual "loop_id", type: :string, as: "(upper(\"left\"((COALESCE(prefix, ''::character varying))::text, 1)) || lpad((serial)::text, 4, '0'::text))", stored: true
    t.index ["discipline_id", "full_tag"], name: "index_tags_on_discipline_and_full_tag", unique: true
    t.index ["discipline_id"], name: "index_tags_on_discipline_id"
    t.index ["loop_id"], name: "index_tags_on_loop_id"
    t.index ["tagable_type", "tagable_id"], name: "index_tags_on_tagable"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", default: "", null: false
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

  create_table "versions", force: :cascade do |t|
    t.bigint "whodunnit"
    t.datetime "created_at"
    t.bigint "item_id", null: false
    t.string "item_type", null: false
    t.string "event", null: false
    t.jsonb "object"
    t.bigint "project_id"
    t.string "ip"
    t.string "user_agent"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
    t.index ["project_id"], name: "index_versions_on_project_id"
  end

  add_foreign_key "disciplines", "projects"
  add_foreign_key "disciplines", "swatches"
  add_foreign_key "doc_types", "disciplines"
  add_foreign_key "documents", "disciplines"
  add_foreign_key "documents", "doc_types"
  add_foreign_key "electrical_cable_types", "disciplines"
  add_foreign_key "electrical_cables", "electrical_cable_types"
  add_foreign_key "electrical_circuits", "electrical_switchboards"
  add_foreign_key "issues", "source_formats"
  add_foreign_key "projects", "swatches"
  add_foreign_key "tags", "disciplines"
end
