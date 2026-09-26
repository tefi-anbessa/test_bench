# app/models/import/batch.rb
module Import
  # Staging record for one spreadsheet-import wizard run (upload -> map
  # columns -> dry-run review -> commit). Ephemeral by design - see
  # expires_at - since it exists only to carry the uploaded file and the
  # user's confirmed column mapping between requests, not as a lasting audit
  # record of what was imported.
  class Batch < ApplicationRecord
    self.table_name = "import_batches"

    # "imported", not "committed" - the latter's bang method (`committed!`)
    # collides with ActiveRecord::Persistence's own internal transaction
    # callback method of the same name (confirmed the hard way).
    enum :status, { uploaded: 0, mapped: 1, validated: 2, imported: 3, aborted: 4 }

    belongs_to :user
    belongs_to :project
    belongs_to :discipline, optional: true

    validates :importer_key, presence: true
    validates :original_filename, presence: true
    validates :file_data, presence: true
    validates :expires_at, presence: true

    scope :expired, -> { where(expires_at: ...Time.current) }

    before_validation :set_default_expiry, on: :create

    def importer_class
      Import::Base.registered(importer_key)
    end

    def importer
      importer_class.new(self)
    end

    private

    def set_default_expiry
      self.expires_at ||= 1.day.from_now
    end
  end
end
