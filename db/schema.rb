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

ActiveRecord::Schema[8.1].define(version: 2026_06_03_000000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
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

  create_table "document_field_definitions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.string "name", null: false
    t.bigint "organization_id", null: false
    t.datetime "updated_at", null: false
    t.string "value_type", null: false
    t.index ["organization_id", "key"], name: "index_document_field_definitions_on_organization_id_and_key", unique: true
    t.index ["organization_id"], name: "index_document_field_definitions_on_organization_id"
    t.index ["value_type"], name: "index_document_field_definitions_on_value_type"
  end

  create_table "document_template_dependencies", force: :cascade do |t|
    t.text "condition"
    t.datetime "created_at", null: false
    t.bigint "dependent_document_template_id", null: false
    t.bigint "organization_id", null: false
    t.bigint "prerequisite_document_template_id", null: false
    t.datetime "updated_at", null: false
    t.index ["dependent_document_template_id"], name: "idx_dtd_dependent_template"
    t.index ["organization_id", "prerequisite_document_template_id", "dependent_document_template_id"], name: "idx_doc_template_dependencies_unique_edge", unique: true
    t.index ["organization_id"], name: "index_document_template_dependencies_on_organization_id"
    t.index ["prerequisite_document_template_id"], name: "idx_dtd_prerequisite_template"
  end

  create_table "document_template_fields", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "document_field_definition_id", null: false
    t.bigint "document_template_id", null: false
    t.text "notes"
    t.bigint "organization_id", null: false
    t.string "requirement", null: false
    t.datetime "updated_at", null: false
    t.index ["document_field_definition_id"], name: "index_document_template_fields_on_document_field_definition_id"
    t.index ["document_template_id"], name: "index_document_template_fields_on_document_template_id"
    t.index ["organization_id", "document_template_id", "document_field_definition_id"], name: "idx_document_template_fields_unique_field", unique: true
    t.index ["organization_id"], name: "index_document_template_fields_on_organization_id"
    t.index ["requirement"], name: "index_document_template_fields_on_requirement"
  end

  create_table "document_templates", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.text "as_is_risk"
    t.string "category", null: false
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.string "criticality", null: false
    t.text "current_state"
    t.text "description"
    t.string "destinations", default: [], null: false, array: true
    t.string "document_type", null: false
    t.string "generator_roles", default: [], null: false, array: true
    t.string "grain", null: false
    t.text "key_data"
    t.string "name", null: false
    t.string "obligation", null: false
    t.bigint "organization_id", null: false
    t.string "receiver_roles", default: [], null: false, array: true
    t.text "source_of_truth_fields"
    t.integer "step_number"
    t.string "timeline"
    t.datetime "updated_at", null: false
    t.bigint "workflow_phase_id", null: false
    t.index ["criticality"], name: "index_document_templates_on_criticality"
    t.index ["document_type"], name: "index_document_templates_on_document_type"
    t.index ["obligation"], name: "index_document_templates_on_obligation"
    t.index ["organization_id", "code"], name: "index_document_templates_on_organization_id_and_code", unique: true
    t.index ["organization_id", "step_number"], name: "index_document_templates_on_organization_id_and_step_number"
    t.index ["organization_id"], name: "index_document_templates_on_organization_id"
    t.index ["workflow_phase_id"], name: "index_document_templates_on_workflow_phase_id"
  end

  create_table "master_agreements", force: :cascade do |t|
    t.string "agreement_number", null: false
    t.datetime "created_at", null: false
    t.string "currency"
    t.date "effective_on"
    t.date "expires_on"
    t.string "incoterm"
    t.string "name", null: false
    t.text "notes"
    t.bigint "organization_id", null: false
    t.string "payment_terms"
    t.string "status", default: "draft", null: false
    t.bigint "trading_partner_id", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "agreement_number"], name: "idx_on_organization_id_agreement_number_d094c3fd1c", unique: true
    t.index ["organization_id"], name: "index_master_agreements_on_organization_id"
    t.index ["status"], name: "index_master_agreements_on_status"
    t.index ["trading_partner_id"], name: "index_master_agreements_on_trading_partner_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "features", default: {}, null: false
    t.string "name", null: false
    t.string "plan", default: "starter", null: false
    t.string "subdomain", null: false
    t.datetime "updated_at", null: false
    t.index ["subdomain"], name: "index_organizations_on_subdomain", unique: true
  end

  create_table "permissions", force: :cascade do |t|
    t.string "action", null: false
    t.datetime "created_at", null: false
    t.string "resource", null: false
    t.datetime "updated_at", null: false
    t.index ["resource", "action"], name: "index_permissions_on_resource_and_action", unique: true
  end

  create_table "purchase_order_lines", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "hs_code"
    t.decimal "net_weight", precision: 15, scale: 3
    t.bigint "organization_id", null: false
    t.string "packaging"
    t.text "product_description"
    t.bigint "purchase_order_id", null: false
    t.decimal "quantity", precision: 15, scale: 3
    t.string "sku", null: false
    t.string "unit"
    t.decimal "unit_price", precision: 15, scale: 4
    t.datetime "updated_at", null: false
    t.index ["organization_id", "purchase_order_id", "sku"], name: "idx_po_lines_unique_sku_per_po"
    t.index ["organization_id"], name: "index_purchase_order_lines_on_organization_id"
    t.index ["purchase_order_id"], name: "index_purchase_order_lines_on_purchase_order_id"
  end

  create_table "purchase_orders", force: :cascade do |t|
    t.string "consignee_name"
    t.datetime "created_at", null: false
    t.string "currency"
    t.string "destination_country"
    t.string "incoterm"
    t.date "issued_on"
    t.bigint "master_agreement_id", null: false
    t.text "notes"
    t.string "notify_party_name"
    t.bigint "organization_id", null: false
    t.string "po_number", null: false
    t.date "required_ship_on"
    t.string "status", default: "draft", null: false
    t.decimal "total_amount", precision: 15, scale: 2
    t.bigint "trading_partner_id", null: false
    t.datetime "updated_at", null: false
    t.index ["master_agreement_id"], name: "index_purchase_orders_on_master_agreement_id"
    t.index ["organization_id", "po_number"], name: "index_purchase_orders_on_organization_id_and_po_number", unique: true
    t.index ["organization_id"], name: "index_purchase_orders_on_organization_id"
    t.index ["status"], name: "index_purchase_orders_on_status"
    t.index ["trading_partner_id"], name: "index_purchase_orders_on_trading_partner_id"
  end

  create_table "role_permissions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "permission_id", null: false
    t.bigint "role_id", null: false
    t.datetime "updated_at", null: false
    t.index ["permission_id"], name: "index_role_permissions_on_permission_id"
    t.index ["role_id", "permission_id"], name: "index_role_permissions_on_role_id_and_permission_id", unique: true
    t.index ["role_id"], name: "index_role_permissions_on_role_id"
  end

  create_table "roles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description"
    t.string "name", null: false
    t.bigint "organization_id", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "name"], name: "index_roles_on_organization_id_and_name", unique: true
    t.index ["organization_id"], name: "index_roles_on_organization_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "shipment_containers", force: :cascade do |t|
    t.string "container_number", null: false
    t.datetime "created_at", null: false
    t.decimal "gross_weight", precision: 15, scale: 3
    t.decimal "net_weight", precision: 15, scale: 3
    t.bigint "organization_id", null: false
    t.integer "package_count"
    t.string "seal_number"
    t.bigint "shipment_id", null: false
    t.datetime "updated_at", null: false
    t.decimal "vgm", precision: 15, scale: 3
    t.index ["organization_id", "shipment_id", "container_number"], name: "idx_shipment_containers_unique_number", unique: true
    t.index ["organization_id"], name: "index_shipment_containers_on_organization_id"
    t.index ["shipment_id"], name: "index_shipment_containers_on_shipment_id"
  end

  create_table "shipment_document_dependencies", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "organization_id", null: false
    t.bigint "prerequisite_shipment_document_id", null: false
    t.bigint "shipment_document_id", null: false
    t.string "status", default: "open", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "prerequisite_shipment_document_id", "shipment_document_id"], name: "idx_runtime_dependencies_unique_edge", unique: true
    t.index ["organization_id"], name: "index_shipment_document_dependencies_on_organization_id"
    t.index ["prerequisite_shipment_document_id"], name: "idx_runtime_dependency_prerequisite"
    t.index ["shipment_document_id"], name: "index_shipment_document_dependencies_on_shipment_document_id"
    t.index ["status"], name: "index_shipment_document_dependencies_on_status"
  end

  create_table "shipment_document_field_values", force: :cascade do |t|
    t.boolean "confirmed", default: false, null: false
    t.datetime "created_at", null: false
    t.bigint "document_field_definition_id", null: false
    t.bigint "organization_id", null: false
    t.string "raw_value"
    t.bigint "shipment_document_id", null: false
    t.string "source", default: "manual", null: false
    t.datetime "updated_at", null: false
    t.jsonb "value"
    t.index ["document_field_definition_id"], name: "idx_on_document_field_definition_id_e38d564c0e"
    t.index ["organization_id", "shipment_document_id", "document_field_definition_id"], name: "idx_shipment_doc_field_values_unique_field", unique: true
    t.index ["organization_id"], name: "index_shipment_document_field_values_on_organization_id"
    t.index ["shipment_document_id"], name: "index_shipment_document_field_values_on_shipment_document_id"
    t.index ["source"], name: "index_shipment_document_field_values_on_source"
  end

  create_table "shipment_documents", force: :cascade do |t|
    t.string "assigned_role"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.bigint "document_template_id", null: false
    t.bigint "documentable_id", null: false
    t.string "documentable_type", null: false
    t.date "due_on"
    t.bigint "organization_id", null: false
    t.bigint "shipment_id", null: false
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.text "waiver_reason"
    t.index ["document_template_id"], name: "index_shipment_documents_on_document_template_id"
    t.index ["documentable_type", "documentable_id"], name: "idx_on_documentable_type_documentable_id_9226196b30"
    t.index ["organization_id", "shipment_id", "document_template_id", "documentable_type", "documentable_id"], name: "idx_shipment_documents_unique_instance", unique: true
    t.index ["organization_id"], name: "index_shipment_documents_on_organization_id"
    t.index ["shipment_id"], name: "index_shipment_documents_on_shipment_id"
    t.index ["status"], name: "index_shipment_documents_on_status"
  end

  create_table "shipment_lots", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "lot_number", null: false
    t.decimal "net_weight", precision: 15, scale: 3
    t.bigint "organization_id", null: false
    t.text "product_description"
    t.decimal "quantity", precision: 15, scale: 3
    t.bigint "shipment_id", null: false
    t.string "sku"
    t.datetime "updated_at", null: false
    t.index ["organization_id", "shipment_id", "lot_number"], name: "idx_on_organization_id_shipment_id_lot_number_a90e05f03c", unique: true
    t.index ["organization_id"], name: "index_shipment_lots_on_organization_id"
    t.index ["shipment_id"], name: "index_shipment_lots_on_shipment_id"
  end

  create_table "shipments", force: :cascade do |t|
    t.string "booking_number"
    t.datetime "created_at", null: false
    t.string "destination_country"
    t.datetime "eta"
    t.datetime "etd"
    t.string "incoterm"
    t.text "notes"
    t.bigint "organization_id", null: false
    t.string "pod"
    t.string "pol"
    t.bigint "purchase_order_id", null: false
    t.string "shipment_number", null: false
    t.string "status", default: "planning", null: false
    t.datetime "updated_at", null: false
    t.string "vessel"
    t.string "voyage"
    t.index ["organization_id", "shipment_number"], name: "index_shipments_on_organization_id_and_shipment_number", unique: true
    t.index ["organization_id"], name: "index_shipments_on_organization_id"
    t.index ["purchase_order_id"], name: "index_shipments_on_purchase_order_id"
    t.index ["status"], name: "index_shipments_on_status"
  end

  create_table "source_of_truth_checks", force: :cascade do |t|
    t.jsonb "actual_value"
    t.bigint "authoritative_shipment_document_id", null: false
    t.datetime "created_at", null: false
    t.bigint "document_field_definition_id", null: false
    t.jsonb "expected_value"
    t.string "failure_action", null: false
    t.bigint "organization_id", null: false
    t.bigint "shipment_id", null: false
    t.bigint "source_of_truth_rule_id", null: false
    t.string "status", default: "pending", null: false
    t.bigint "target_shipment_document_id", null: false
    t.datetime "updated_at", null: false
    t.index ["authoritative_shipment_document_id"], name: "idx_sot_checks_authoritative_doc"
    t.index ["document_field_definition_id"], name: "index_source_of_truth_checks_on_document_field_definition_id"
    t.index ["organization_id", "shipment_id", "source_of_truth_rule_id", "authoritative_shipment_document_id", "target_shipment_document_id"], name: "idx_sot_checks_unique_runtime_check", unique: true
    t.index ["organization_id"], name: "index_source_of_truth_checks_on_organization_id"
    t.index ["shipment_id"], name: "index_source_of_truth_checks_on_shipment_id"
    t.index ["source_of_truth_rule_id"], name: "index_source_of_truth_checks_on_source_of_truth_rule_id"
    t.index ["status"], name: "index_source_of_truth_checks_on_status"
    t.index ["target_shipment_document_id"], name: "idx_sot_checks_target_doc"
  end

  create_table "source_of_truth_rule_targets", force: :cascade do |t|
    t.text "correction_note"
    t.datetime "created_at", null: false
    t.bigint "document_template_id", null: false
    t.bigint "organization_id", null: false
    t.bigint "source_of_truth_rule_id", null: false
    t.datetime "updated_at", null: false
    t.index ["document_template_id"], name: "index_source_of_truth_rule_targets_on_document_template_id"
    t.index ["organization_id", "source_of_truth_rule_id", "document_template_id"], name: "idx_source_of_truth_rule_targets_unique_target", unique: true
    t.index ["organization_id"], name: "index_source_of_truth_rule_targets_on_organization_id"
    t.index ["source_of_truth_rule_id"], name: "index_source_of_truth_rule_targets_on_source_of_truth_rule_id"
  end

  create_table "source_of_truth_rules", force: :cascade do |t|
    t.bigint "authoritative_document_template_id", null: false
    t.datetime "created_at", null: false
    t.bigint "document_field_definition_id", null: false
    t.string "failure_action", null: false
    t.text "logic", null: false
    t.bigint "organization_id", null: false
    t.datetime "updated_at", null: false
    t.index ["authoritative_document_template_id"], name: "idx_sot_rules_authoritative_template"
    t.index ["document_field_definition_id"], name: "index_source_of_truth_rules_on_document_field_definition_id"
    t.index ["organization_id", "document_field_definition_id", "authoritative_document_template_id"], name: "idx_source_of_truth_rules_unique_authority", unique: true
    t.index ["organization_id"], name: "index_source_of_truth_rules_on_organization_id"
  end

  create_table "trading_partners", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.text "address"
    t.string "country"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "legal_name"
    t.string "name", null: false
    t.bigint "organization_id", null: false
    t.string "partner_type", default: "buyer", null: false
    t.string "phone"
    t.string "tax_identifier"
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_trading_partners_on_active"
    t.index ["organization_id", "legal_name"], name: "index_trading_partners_on_organization_id_and_legal_name", unique: true, where: "(legal_name IS NOT NULL)"
    t.index ["organization_id", "name"], name: "index_trading_partners_on_organization_id_and_name", unique: true
    t.index ["organization_id"], name: "index_trading_partners_on_organization_id"
    t.index ["partner_type"], name: "index_trading_partners_on_partner_type"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "first_name"
    t.string "last_name"
    t.bigint "organization_id"
    t.string "password_digest", null: false
    t.bigint "role_id"
    t.boolean "superadmin", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["organization_id"], name: "index_users_on_organization_id"
    t.index ["role_id"], name: "index_users_on_role_id"
  end

  create_table "versions", force: :cascade do |t|
    t.datetime "created_at"
    t.string "event", null: false
    t.bigint "item_id", null: false
    t.string "item_type", null: false
    t.text "object"
    t.text "object_changes"
    t.string "whodunnit"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  create_table "workflow_phases", force: :cascade do |t|
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.bigint "organization_id", null: false
    t.string "owner_role"
    t.integer "position", null: false
    t.string "timeline_end"
    t.string "timeline_start"
    t.datetime "updated_at", null: false
    t.index ["organization_id", "code"], name: "index_workflow_phases_on_organization_id_and_code", unique: true
    t.index ["organization_id", "position"], name: "index_workflow_phases_on_organization_id_and_position", unique: true
    t.index ["organization_id"], name: "index_workflow_phases_on_organization_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "document_field_definitions", "organizations"
  add_foreign_key "document_template_dependencies", "document_templates", column: "dependent_document_template_id"
  add_foreign_key "document_template_dependencies", "document_templates", column: "prerequisite_document_template_id"
  add_foreign_key "document_template_dependencies", "organizations"
  add_foreign_key "document_template_fields", "document_field_definitions"
  add_foreign_key "document_template_fields", "document_templates"
  add_foreign_key "document_template_fields", "organizations"
  add_foreign_key "document_templates", "organizations"
  add_foreign_key "document_templates", "workflow_phases"
  add_foreign_key "master_agreements", "organizations"
  add_foreign_key "master_agreements", "trading_partners"
  add_foreign_key "purchase_order_lines", "organizations"
  add_foreign_key "purchase_order_lines", "purchase_orders"
  add_foreign_key "purchase_orders", "master_agreements"
  add_foreign_key "purchase_orders", "organizations"
  add_foreign_key "purchase_orders", "trading_partners"
  add_foreign_key "role_permissions", "permissions"
  add_foreign_key "role_permissions", "roles"
  add_foreign_key "roles", "organizations"
  add_foreign_key "sessions", "users"
  add_foreign_key "shipment_containers", "organizations"
  add_foreign_key "shipment_containers", "shipments"
  add_foreign_key "shipment_document_dependencies", "organizations"
  add_foreign_key "shipment_document_dependencies", "shipment_documents"
  add_foreign_key "shipment_document_dependencies", "shipment_documents", column: "prerequisite_shipment_document_id"
  add_foreign_key "shipment_document_field_values", "document_field_definitions"
  add_foreign_key "shipment_document_field_values", "organizations"
  add_foreign_key "shipment_document_field_values", "shipment_documents"
  add_foreign_key "shipment_documents", "document_templates"
  add_foreign_key "shipment_documents", "organizations"
  add_foreign_key "shipment_documents", "shipments"
  add_foreign_key "shipment_lots", "organizations"
  add_foreign_key "shipment_lots", "shipments"
  add_foreign_key "shipments", "organizations"
  add_foreign_key "shipments", "purchase_orders"
  add_foreign_key "source_of_truth_checks", "document_field_definitions"
  add_foreign_key "source_of_truth_checks", "organizations"
  add_foreign_key "source_of_truth_checks", "shipment_documents", column: "authoritative_shipment_document_id"
  add_foreign_key "source_of_truth_checks", "shipment_documents", column: "target_shipment_document_id"
  add_foreign_key "source_of_truth_checks", "shipments"
  add_foreign_key "source_of_truth_checks", "source_of_truth_rules"
  add_foreign_key "source_of_truth_rule_targets", "document_templates"
  add_foreign_key "source_of_truth_rule_targets", "organizations"
  add_foreign_key "source_of_truth_rule_targets", "source_of_truth_rules"
  add_foreign_key "source_of_truth_rules", "document_field_definitions"
  add_foreign_key "source_of_truth_rules", "document_templates", column: "authoritative_document_template_id"
  add_foreign_key "source_of_truth_rules", "organizations"
  add_foreign_key "trading_partners", "organizations"
  add_foreign_key "users", "organizations"
  add_foreign_key "users", "roles"
  add_foreign_key "workflow_phases", "organizations"
end
