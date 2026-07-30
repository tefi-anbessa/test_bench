# frozen_string_literal: true
module ChangeManagement
  class Request < Base
    # === Mixins ===

    # === Constants ===
    # enum declarations
    enum :duration, Constants.change_management.request.duration.to_h

    # === Gem macros ===
    has_paper_trail

    # === Attributes ===
    # Lock CR number after creation
    attr_readonly :project_id, :serial

    # === Associations ===
    belongs_to :project

    # === Scopes ===

    # === Validations ===
    # Presence validation for required fields.
    validates :title, presence: true, 
      length: { maximum: 255 }, uniqueness: { scope: :project_id }
    validates :reason, presence: true
    validates :summary, presence: true
    validates :duration, presence: true
    # Uniqueness validation for unique fields.
    validates :serial, uniqueness: { scope: :project_id }

    # === Callbacks ===
    around_create :set_request_number

    # === Class methods ===
    def self.swatch
      Swatch.find_by(name: "app_theme")
    end

    # === Class methods - Queries ===
    # Provide SQL for ordering swatches in the navigator
    def self.navigator_order_sql
    <<~SQL.squish
      projects.code ASC,
      project_change_requests.serial ASC
    SQL
    end

    # === Public methods ===
    def label
      "CR #{serial}"
    end

    def long_label
      "CR #{project.label}-#{serial}"
    end

    # === Private methods ===
    private
      def set_request_number
        ProjectChange::Request.transaction do
          # Lock existing records for this discipline/doc_type combination
          ProjectChange::Request.where(project_id: project_id)
                  .lock
          
          # Now safely set serial number
          max_serial = ProjectChange::Request.where(project_id: project_id)
                              .maximum(:serial) || 0
          self.serial = max_serial.to_i + 1
          # Continue with the create (yield runs the actual save)
          yield
        end
      end

      def self.ransackable_attributes(auth_object = nil)
        [:title, :reason, :summary, :duration, :created_at, :updated_at]
      end

      def self.ransackable_associations(auth_object = nil)
        [:project]
      end
  end
end
