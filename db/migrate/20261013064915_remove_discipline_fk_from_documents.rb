class RemoveDisciplineFkFromDocuments < ActiveRecord::Migration[8.0]
  def up
    # A document's own discipline_id (set from the create-form's route) could
    # disagree with its doc_type's discipline (set from the create-form's
    # doc_type dropdown, which wasn't discipline-scoped - see
    # DocumentsController#setup_form). Remove any document left in that
    # inconsistent state before dropping the redundant column - dev-only,
    # confirmed no real data, just seeds/test junk from that bug.
    Document.joins(:doc_type).where("documents.discipline_id != doc_types.discipline_id").destroy_all

    remove_index :documents, column: [:serial, :discipline_id, :doc_type_id],
      name: "index_documents_on_serial_and_discipline_id_and_doc_type_id"
    remove_foreign_key :documents, :disciplines
    remove_column :documents, :discipline_id

    add_index :documents, [:serial, :doc_type_id], unique: true,
      name: "index_documents_on_serial_and_doc_type_id"
  end

  def down
    add_column :documents, :discipline_id, :bigint
    add_foreign_key :documents, :disciplines
    remove_index :documents, column: [:serial, :doc_type_id],
      name: "index_documents_on_serial_and_doc_type_id"

    # Backfill from doc_type - the deleted inconsistent rows can't be
    # restored, and this is the only source left for the rest.
    execute <<~SQL
      UPDATE documents SET discipline_id = doc_types.discipline_id
      FROM doc_types WHERE documents.doc_type_id = doc_types.id
    SQL

    add_index :documents, [:serial, :discipline_id, :doc_type_id], unique: true,
      name: "index_documents_on_serial_and_discipline_id_and_doc_type_id"
  end
end
