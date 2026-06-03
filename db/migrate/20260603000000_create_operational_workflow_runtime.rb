class CreateOperationalWorkflowRuntime < ActiveRecord::Migration[8.1]
  def change
    create_table :trading_partners do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :name, null: false
      t.string :legal_name
      t.string :partner_type, null: false, default: "buyer"
      t.string :tax_identifier
      t.string :country
      t.string :email
      t.string :phone
      t.text :address
      t.boolean :active, null: false, default: true

      t.timestamps
    end
    add_index :trading_partners, %i[organization_id name], unique: true
    add_index :trading_partners, %i[organization_id legal_name], unique: true, where: "legal_name IS NOT NULL"
    add_index :trading_partners, :partner_type
    add_index :trading_partners, :active

    create_table :master_agreements do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :trading_partner, null: false, foreign_key: true
      t.string :agreement_number, null: false
      t.string :name, null: false
      t.string :status, null: false, default: "draft"
      t.date :effective_on
      t.date :expires_on
      t.string :incoterm
      t.string :payment_terms
      t.string :currency
      t.text :notes

      t.timestamps
    end
    add_index :master_agreements, %i[organization_id agreement_number], unique: true
    add_index :master_agreements, :status

    create_table :purchase_orders do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :trading_partner, null: false, foreign_key: true
      t.references :master_agreement, null: false, foreign_key: true
      t.string :po_number, null: false
      t.string :status, null: false, default: "draft"
      t.date :issued_on
      t.date :required_ship_on
      t.string :destination_country
      t.string :consignee_name
      t.string :notify_party_name
      t.string :incoterm
      t.string :currency
      t.decimal :total_amount, precision: 15, scale: 2
      t.text :notes

      t.timestamps
    end
    add_index :purchase_orders, %i[organization_id po_number], unique: true
    add_index :purchase_orders, :status

    create_table :purchase_order_lines do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :purchase_order, null: false, foreign_key: true
      t.string :sku, null: false
      t.text :product_description
      t.string :hs_code
      t.decimal :quantity, precision: 15, scale: 3
      t.string :unit
      t.decimal :unit_price, precision: 15, scale: 4
      t.decimal :net_weight, precision: 15, scale: 3
      t.string :packaging

      t.timestamps
    end
    add_index :purchase_order_lines, %i[organization_id purchase_order_id sku], name: "idx_po_lines_unique_sku_per_po"

    create_table :shipments do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :purchase_order, null: false, foreign_key: true
      t.string :shipment_number, null: false
      t.string :status, null: false, default: "planning"
      t.datetime :etd
      t.datetime :eta
      t.string :pol
      t.string :pod
      t.string :booking_number
      t.string :vessel
      t.string :voyage
      t.string :incoterm
      t.string :destination_country
      t.text :notes

      t.timestamps
    end
    add_index :shipments, %i[organization_id shipment_number], unique: true
    add_index :shipments, :status

    create_table :shipment_lots do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :shipment, null: false, foreign_key: true
      t.string :lot_number, null: false
      t.string :sku
      t.text :product_description
      t.decimal :quantity, precision: 15, scale: 3
      t.decimal :net_weight, precision: 15, scale: 3

      t.timestamps
    end
    add_index :shipment_lots, %i[organization_id shipment_id lot_number], unique: true

    create_table :shipment_containers do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :shipment, null: false, foreign_key: true
      t.string :container_number, null: false
      t.string :seal_number
      t.decimal :vgm, precision: 15, scale: 3
      t.decimal :gross_weight, precision: 15, scale: 3
      t.decimal :net_weight, precision: 15, scale: 3
      t.integer :package_count

      t.timestamps
    end
    add_index :shipment_containers, %i[organization_id shipment_id container_number], unique: true, name: "idx_shipment_containers_unique_number"

    create_table :shipment_documents do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :shipment, null: false, foreign_key: true
      t.references :document_template, null: false, foreign_key: true
      t.string :documentable_type, null: false
      t.bigint :documentable_id, null: false
      t.string :status, null: false, default: "pending"
      t.date :due_on
      t.datetime :completed_at
      t.string :assigned_role
      t.text :waiver_reason

      t.timestamps
    end
    add_index :shipment_documents, %i[documentable_type documentable_id]
    add_index :shipment_documents,
              %i[organization_id shipment_id document_template_id documentable_type documentable_id],
              unique: true,
              name: "idx_shipment_documents_unique_instance"
    add_index :shipment_documents, :status

    create_table :shipment_document_field_values do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :shipment_document, null: false, foreign_key: true
      t.references :document_field_definition, null: false, foreign_key: true
      t.jsonb :value
      t.string :raw_value
      t.string :source, null: false, default: "manual"
      t.boolean :confirmed, null: false, default: false

      t.timestamps
    end
    add_index :shipment_document_field_values,
              %i[organization_id shipment_document_id document_field_definition_id],
              unique: true,
              name: "idx_shipment_doc_field_values_unique_field"
    add_index :shipment_document_field_values, :source

    create_table :shipment_document_dependencies do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :shipment_document, null: false, foreign_key: true
      t.references :prerequisite_shipment_document,
                   null: false,
                   foreign_key: { to_table: :shipment_documents },
                   index: { name: "idx_runtime_dependency_prerequisite" }
      t.string :status, null: false, default: "open"

      t.timestamps
    end
    add_index :shipment_document_dependencies,
              %i[organization_id prerequisite_shipment_document_id shipment_document_id],
              unique: true,
              name: "idx_runtime_dependencies_unique_edge"
    add_index :shipment_document_dependencies, :status

    create_table :source_of_truth_checks do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :shipment, null: false, foreign_key: true
      t.references :source_of_truth_rule, null: false, foreign_key: true
      t.references :authoritative_shipment_document,
                   null: false,
                   foreign_key: { to_table: :shipment_documents },
                   index: { name: "idx_sot_checks_authoritative_doc" }
      t.references :target_shipment_document,
                   null: false,
                   foreign_key: { to_table: :shipment_documents },
                   index: { name: "idx_sot_checks_target_doc" }
      t.references :document_field_definition, null: false, foreign_key: true
      t.string :status, null: false, default: "pending"
      t.jsonb :expected_value
      t.jsonb :actual_value
      t.string :failure_action, null: false

      t.timestamps
    end
    add_index :source_of_truth_checks,
              %i[organization_id shipment_id source_of_truth_rule_id authoritative_shipment_document_id target_shipment_document_id],
              unique: true,
              name: "idx_sot_checks_unique_runtime_check"
    add_index :source_of_truth_checks, :status
  end
end
