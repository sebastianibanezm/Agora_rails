class CreateWorkflowTemplateFoundation < ActiveRecord::Migration[8.1]
  def change
    create_table :workflow_phases do |t|
      t.references :organization, null: false, foreign_key: true
      t.integer :position, null: false
      t.string :code, null: false
      t.string :name, null: false
      t.string :owner_role
      t.string :timeline_start
      t.string :timeline_end
      t.text :description

      t.timestamps
    end
    add_index :workflow_phases, %i[organization_id position], unique: true
    add_index :workflow_phases, %i[organization_id code], unique: true

    create_table :document_templates do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :workflow_phase, null: false, foreign_key: true
      t.integer :step_number
      t.string :code, null: false
      t.string :name, null: false
      t.string :timeline
      t.string :document_type, null: false
      t.string :category, null: false
      t.string :obligation, null: false
      t.string :criticality, null: false
      t.string :grain, null: false
      t.string :destinations, array: true, default: [], null: false
      t.string :generator_roles, array: true, default: [], null: false
      t.string :receiver_roles, array: true, default: [], null: false
      t.text :description
      t.text :current_state
      t.text :as_is_risk
      t.text :source_of_truth_fields
      t.text :key_data
      t.boolean :active, default: true, null: false

      t.timestamps
    end
    add_index :document_templates, %i[organization_id code], unique: true
    add_index :document_templates, %i[organization_id step_number]
    add_index :document_templates, :document_type
    add_index :document_templates, :obligation
    add_index :document_templates, :criticality

    create_table :document_template_dependencies do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :prerequisite_document_template,
                   null: false,
                   foreign_key: { to_table: :document_templates },
                   index: { name: "idx_dtd_prerequisite_template" }
      t.references :dependent_document_template,
                   null: false,
                   foreign_key: { to_table: :document_templates },
                   index: { name: "idx_dtd_dependent_template" }
      t.text :condition

      t.timestamps
    end
    add_index :document_template_dependencies,
              %i[organization_id prerequisite_document_template_id dependent_document_template_id],
              unique: true,
              name: "idx_doc_template_dependencies_unique_edge"

    create_table :document_field_definitions do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :key, null: false
      t.string :name, null: false
      t.string :value_type, null: false
      t.text :description

      t.timestamps
    end
    add_index :document_field_definitions, %i[organization_id key], unique: true
    add_index :document_field_definitions, :value_type

    create_table :document_template_fields do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :document_template, null: false, foreign_key: true
      t.references :document_field_definition, null: false, foreign_key: true
      t.string :requirement, null: false
      t.text :notes

      t.timestamps
    end
    add_index :document_template_fields,
              %i[organization_id document_template_id document_field_definition_id],
              unique: true,
              name: "idx_document_template_fields_unique_field"
    add_index :document_template_fields, :requirement

    create_table :source_of_truth_rules do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :document_field_definition, null: false, foreign_key: true
      t.references :authoritative_document_template,
                   null: false,
                   foreign_key: { to_table: :document_templates },
                   index: { name: "idx_sot_rules_authoritative_template" }
      t.text :logic, null: false
      t.string :failure_action, null: false

      t.timestamps
    end
    add_index :source_of_truth_rules,
              %i[organization_id document_field_definition_id authoritative_document_template_id],
              unique: true,
              name: "idx_source_of_truth_rules_unique_authority"

    create_table :source_of_truth_rule_targets do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :source_of_truth_rule, null: false, foreign_key: true
      t.references :document_template, null: false, foreign_key: true
      t.text :correction_note

      t.timestamps
    end
    add_index :source_of_truth_rule_targets,
              %i[organization_id source_of_truth_rule_id document_template_id],
              unique: true,
              name: "idx_source_of_truth_rule_targets_unique_target"
  end
end
