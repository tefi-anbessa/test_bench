class CreateImportBatches < ActiveRecord::Migration[8.0]
  def change
    create_table :import_batches do |t|
      t.bigint :user_id, null: false
      t.bigint :project_id, null: false
      # Set for discipline-scoped imports, and for project-wide imports where
      # the user picked a single discipline for the whole file rather than
      # mapping a discipline column - left null when a discipline column is
      # mapped, since each row then resolves its own discipline.
      t.bigint :discipline_id
      # Registry key looked up in Import::Base (e.g. "tags") - which importer
      # plugin this batch belongs to.
      t.string :importer_key, null: false
      t.string :original_filename, null: false
      # The raw uploaded bytes. Stored in Postgres rather than on local disk:
      # the app deploys containerized (see dockerfile-rails in the Gemfile),
      # so a wizard step landing on a different instance can't rely on a tmp
      # file surviving between requests - a DB row has no such risk, and at
      # the row counts this import is designed for (hundreds-to-low-thousands
      # per file) bytea storage is a non-issue.
      t.binary :file_data, null: false
      # Confirmed sheet-header -> column-definition-key mapping, plus the
      # single-discipline-for-batch choice when that path was used.
      t.jsonb :column_mapping, null: false, default: {}
      t.integer :status, null: false, default: 0
      t.integer :row_count
      # Ephemeral by design - swept opportunistically (the current user's
      # expired batches are deleted on the import wizard's entry action)
      # since there's no background job/cron infrastructure for a proper
      # sweep yet.
      t.datetime :expires_at, null: false

      t.timestamps
    end

    add_foreign_key :import_batches, :projects
    add_foreign_key :import_batches, :disciplines
    add_index :import_batches, :user_id
    add_index :import_batches, :expires_at
  end
end
