class EnforceCanonicalMasterAgreementDocuments < ActiveRecord::Migration[8.0]
  INDEX_NAME = "idx_shipment_documents_unique_master_agreement_doc"

  def up
    canonicalize_master_agreement_documents

    add_index :shipment_documents,
              %i[organization_id document_template_id documentable_type documentable_id],
              unique: true,
              where: "documentable_type = 'MasterAgreement'",
              name: INDEX_NAME
  end

  def down
    remove_index :shipment_documents, name: INDEX_NAME
  end

  private

    def canonicalize_master_agreement_documents
      duplicate_groups.each do |group|
        ids = pg_array(group.fetch("ids"))
        canonical_id = ids.first

        ids.drop(1).each do |duplicate_id|
          merge_field_values(canonical_id, duplicate_id)
          merge_dependencies(canonical_id, duplicate_id)
          merge_source_of_truth_checks(canonical_id, duplicate_id)
          merge_active_storage_attachments(canonical_id, duplicate_id)
          execute(sql([ "DELETE FROM shipment_documents WHERE id = ?", duplicate_id ]))
        end
      end
    end

    def duplicate_groups
      select_all(<<~SQL)
        SELECT organization_id,
               document_template_id,
               documentable_type,
               documentable_id,
               ARRAY_AGG(id ORDER BY created_at, id) AS ids
        FROM shipment_documents
        WHERE documentable_type = 'MasterAgreement'
        GROUP BY organization_id, document_template_id, documentable_type, documentable_id
        HAVING COUNT(*) > 1
      SQL
    end

    def merge_field_values(canonical_id, duplicate_id)
      select_all(sql([
        "SELECT * FROM shipment_document_field_values WHERE shipment_document_id = ?",
        duplicate_id
      ])).each do |field_value|
        existing = select_value(sql([
          <<~SQL.squish,
            SELECT id
            FROM shipment_document_field_values
            WHERE organization_id = ?
              AND shipment_document_id = ?
              AND document_field_definition_id = ?
          SQL
          field_value.fetch("organization_id"),
          canonical_id,
          field_value.fetch("document_field_definition_id")
        ]))

        if existing
          execute(sql([ "DELETE FROM shipment_document_field_values WHERE id = ?", field_value.fetch("id") ]))
        else
          execute(sql([
            "UPDATE shipment_document_field_values SET shipment_document_id = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?",
            canonical_id,
            field_value.fetch("id")
          ]))
        end
      end
    end

    def merge_dependencies(canonical_id, duplicate_id)
      select_all(sql([
        <<~SQL.squish,
          SELECT id, organization_id, shipment_document_id, prerequisite_shipment_document_id
          FROM shipment_document_dependencies
          WHERE shipment_document_id = ? OR prerequisite_shipment_document_id = ?
        SQL
        duplicate_id,
        duplicate_id
      ])).each do |dependency|
        next_dependent_id = dependency.fetch("shipment_document_id") == duplicate_id ? canonical_id : dependency.fetch("shipment_document_id")
        next_prerequisite_id = dependency.fetch("prerequisite_shipment_document_id") == duplicate_id ? canonical_id : dependency.fetch("prerequisite_shipment_document_id")

        if next_dependent_id == next_prerequisite_id || dependency_exists?(dependency.fetch("organization_id"), next_dependent_id, next_prerequisite_id)
          execute(sql([ "DELETE FROM shipment_document_dependencies WHERE id = ?", dependency.fetch("id") ]))
        else
          execute(sql([
            <<~SQL.squish,
              UPDATE shipment_document_dependencies
              SET shipment_document_id = ?, prerequisite_shipment_document_id = ?, updated_at = CURRENT_TIMESTAMP
              WHERE id = ?
            SQL
            next_dependent_id,
            next_prerequisite_id,
            dependency.fetch("id")
          ]))
        end
      end
    end

    def merge_source_of_truth_checks(canonical_id, duplicate_id)
      select_all(sql([
        <<~SQL.squish,
          SELECT id, organization_id, shipment_id, source_of_truth_rule_id,
                 authoritative_shipment_document_id, target_shipment_document_id
          FROM source_of_truth_checks
          WHERE authoritative_shipment_document_id = ? OR target_shipment_document_id = ?
        SQL
        duplicate_id,
        duplicate_id
      ])).each do |check|
        next_authoritative_id = check.fetch("authoritative_shipment_document_id") == duplicate_id ? canonical_id : check.fetch("authoritative_shipment_document_id")
        next_target_id = check.fetch("target_shipment_document_id") == duplicate_id ? canonical_id : check.fetch("target_shipment_document_id")

        if next_authoritative_id == next_target_id || source_check_exists?(check, next_authoritative_id, next_target_id)
          execute(sql([ "DELETE FROM source_of_truth_checks WHERE id = ?", check.fetch("id") ]))
        else
          execute(sql([
            <<~SQL.squish,
              UPDATE source_of_truth_checks
              SET authoritative_shipment_document_id = ?, target_shipment_document_id = ?, updated_at = CURRENT_TIMESTAMP
              WHERE id = ?
            SQL
            next_authoritative_id,
            next_target_id,
            check.fetch("id")
          ]))
        end
      end
    end

    def merge_active_storage_attachments(canonical_id, duplicate_id)
      return unless table_exists?(:active_storage_attachments)

      select_all(sql([
        <<~SQL.squish,
          SELECT id, name, blob_id
          FROM active_storage_attachments
          WHERE record_type = 'ShipmentDocument' AND record_id = ?
        SQL
        duplicate_id
      ])).each do |attachment|
        existing = select_value(sql([
          <<~SQL.squish,
            SELECT id
            FROM active_storage_attachments
            WHERE record_type = 'ShipmentDocument'
              AND record_id = ?
              AND name = ?
              AND blob_id = ?
          SQL
          canonical_id,
          attachment.fetch("name"),
          attachment.fetch("blob_id")
        ]))

        if existing
          execute(sql([ "DELETE FROM active_storage_attachments WHERE id = ?", attachment.fetch("id") ]))
        else
          execute(sql([
            "UPDATE active_storage_attachments SET record_id = ? WHERE id = ?",
            canonical_id,
            attachment.fetch("id")
          ]))
        end
      end
    end

    def dependency_exists?(organization_id, shipment_document_id, prerequisite_shipment_document_id)
      select_value(sql([
        <<~SQL.squish,
          SELECT id
          FROM shipment_document_dependencies
          WHERE organization_id = ?
            AND shipment_document_id = ?
            AND prerequisite_shipment_document_id = ?
        SQL
        organization_id,
        shipment_document_id,
        prerequisite_shipment_document_id
      ]))
    end

    def source_check_exists?(check, authoritative_id, target_id)
      select_value(sql([
        <<~SQL.squish,
          SELECT id
          FROM source_of_truth_checks
          WHERE organization_id = ?
            AND shipment_id = ?
            AND source_of_truth_rule_id = ?
            AND authoritative_shipment_document_id = ?
            AND target_shipment_document_id = ?
        SQL
        check.fetch("organization_id"),
        check.fetch("shipment_id"),
        check.fetch("source_of_truth_rule_id"),
        authoritative_id,
        target_id
      ]))
    end

    def sql(statement)
      ActiveRecord::Base.sanitize_sql_array(statement)
    end

    def pg_array(value)
      return value if value.is_a?(Array)

      value.to_s.delete_prefix("{").delete_suffix("}").split(",").map(&:to_i)
    end
end
