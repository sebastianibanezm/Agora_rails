class CreateMasterAgreementExtractionModels < ActiveRecord::Migration[8.1]
  def change
    create_table :master_agreement_documents do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :master_agreement, null: false, foreign_key: true
      t.string :document_kind, null: false
      t.string :title, null: false
      t.date :effective_on
      t.date :expires_on
      t.string :extraction_status, null: false, default: "not_started"
      t.text :extraction_error
      t.text :extracted_text
      t.jsonb :extracted_data, null: false, default: {}
      t.string :docusign_envelope_id
      t.string :docusign_status
      t.string :docusign_subject
      t.string :docusign_originator_name
      t.string :docusign_originator_email
      t.string :docusign_time_zone
      t.datetime :reviewed_at
      t.references :reviewed_by, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :master_agreement_documents, %i[organization_id master_agreement_id document_kind], name: "idx_ma_docs_on_agreement_kind"
    add_index :master_agreement_documents, :extraction_status
    add_index :master_agreement_documents, :docusign_envelope_id

    create_table :master_agreement_extracted_values do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :master_agreement, null: false, foreign_key: true
      t.references :master_agreement_document, null: false, foreign_key: true
      t.string :field_key, null: false
      t.string :label, null: false
      t.string :raw_value
      t.jsonb :normalized_value, null: false, default: {}
      t.string :source_label
      t.integer :page_number
      t.decimal :confidence, precision: 5, scale: 4
      t.string :review_status, null: false, default: "pending_review"
      t.datetime :reviewed_at
      t.references :reviewed_by, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :master_agreement_extracted_values,
              %i[organization_id master_agreement_document_id field_key source_label page_number],
              name: "idx_ma_values_source"
    add_index :master_agreement_extracted_values, :review_status

    create_table :master_agreement_parties do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :master_agreement, null: false, foreign_key: true
      t.references :master_agreement_document, foreign_key: true
      t.string :party_role, null: false
      t.string :name, null: false
      t.string :legal_name
      t.string :state_of_incorporation
      t.integer :source_page
      t.decimal :confidence, precision: 5, scale: 4
      t.string :review_status, null: false, default: "pending_review"
      t.timestamps
    end
    add_index :master_agreement_parties, %i[organization_id master_agreement_id party_role name], name: "idx_ma_parties_role_name"
    add_index :master_agreement_parties, :review_status

    create_table :master_agreement_contacts do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :master_agreement, null: false, foreign_key: true
      t.references :master_agreement_document, foreign_key: true
      t.string :contact_type, null: false
      t.string :party_role
      t.string :name
      t.string :title
      t.string :phone
      t.string :email
      t.text :address
      t.integer :source_page
      t.decimal :confidence, precision: 5, scale: 4
      t.string :review_status, null: false, default: "pending_review"
      t.timestamps
    end
    add_index :master_agreement_contacts, %i[organization_id master_agreement_id contact_type], name: "idx_ma_contacts_type"
    add_index :master_agreement_contacts, :review_status

    create_table :master_agreement_signers do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :master_agreement, null: false, foreign_key: true
      t.references :master_agreement_document, null: false, foreign_key: true
      t.string :party_role, null: false
      t.string :name, null: false
      t.string :email
      t.string :title
      t.string :company
      t.datetime :sent_at
      t.datetime :viewed_at
      t.datetime :signed_at
      t.datetime :disclosure_accepted_at
      t.string :ip_address
      t.string :signature_method
      t.integer :source_page
      t.decimal :confidence, precision: 5, scale: 4
      t.string :review_status, null: false, default: "pending_review"
      t.timestamps
    end
    add_index :master_agreement_signers, %i[organization_id master_agreement_document_id party_role name], name: "idx_ma_signers_role_name"
    add_index :master_agreement_signers, :review_status

    create_table :master_agreement_schedules do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :master_agreement, null: false, foreign_key: true
      t.references :master_agreement_document, null: false, foreign_key: true
      t.string :schedule_number
      t.string :title, null: false
      t.string :product_category
      t.string :currency
      t.date :effective_on
      t.date :expires_on
      t.date :first_delivery_on
      t.string :payment_terms
      t.integer :lead_time_days
      t.string :lead_time_description
      t.text :delivery_terms
      t.text :specifications_reference
      t.text :incentives
      t.text :unsaleables_terms
      t.text :pricing_adjustment_terms
      t.string :participating_companies, null: false, default: [], array: true
      t.string :distributors, null: false, default: [], array: true
      t.string :pallet_requirements, null: false, default: [], array: true
      t.integer :source_page
      t.decimal :confidence, precision: 5, scale: 4
      t.string :review_status, null: false, default: "pending_review"
      t.timestamps
    end
    add_index :master_agreement_schedules, %i[organization_id master_agreement_id title], name: "idx_ma_schedules_title"
    add_index :master_agreement_schedules, :review_status

    create_table :master_agreement_delivery_locations do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :master_agreement, null: false, foreign_key: true
      t.references :master_agreement_schedule, null: false, foreign_key: true
      t.string :code
      t.string :name, null: false
      t.text :address
      t.string :city
      t.string :state_region
      t.string :postal_code
      t.string :country
      t.integer :source_page
      t.decimal :confidence, precision: 5, scale: 4
      t.string :review_status, null: false, default: "pending_review"
      t.timestamps
    end
    add_index :master_agreement_delivery_locations, %i[organization_id master_agreement_schedule_id name], name: "idx_ma_locations_schedule_name"
    add_index :master_agreement_delivery_locations, :review_status

    create_table :master_agreement_product_price_lines do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :master_agreement, null: false, foreign_key: true
      t.references :master_agreement_schedule, null: false, foreign_key: true
      t.string :participating_company, null: false
      t.string :product_description, null: false
      t.integer :case_pack
      t.decimal :size, precision: 12, scale: 3
      t.string :uom
      t.decimal :unit_cost_delivered, precision: 15, scale: 4
      t.string :currency
      t.integer :source_page
      t.decimal :confidence, precision: 5, scale: 4
      t.string :review_status, null: false, default: "pending_review"
      t.timestamps
    end
    add_index :master_agreement_product_price_lines,
              %i[organization_id master_agreement_schedule_id participating_company product_description],
              name: "idx_ma_price_lines_product"
    add_index :master_agreement_product_price_lines, :review_status

    create_table :master_agreement_clauses do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :master_agreement, null: false, foreign_key: true
      t.references :master_agreement_document, null: false, foreign_key: true
      t.string :section_number, null: false
      t.string :title, null: false
      t.text :summary
      t.jsonb :obligations, null: false, default: []
      t.integer :source_page
      t.decimal :confidence, precision: 5, scale: 4
      t.string :review_status, null: false, default: "pending_review"
      t.timestamps
    end
    add_index :master_agreement_clauses, %i[organization_id master_agreement_document_id section_number], name: "idx_ma_clauses_section"
    add_index :master_agreement_clauses, :review_status
  end
end
