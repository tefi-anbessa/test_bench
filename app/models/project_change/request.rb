# frozen_string_literal: true
module ProjectChange
  class Request < Base
    # Callbacks
    around_create :set_request_number

    # Belongs to associatons
    belongs_to :project, inverse_of: :change_requests
    
    # enum declarations
    enum :duration, Constants.project_change.request.duration.to_h
    
    # Presence validation for required fields.
    validates :title, presence: true, 
      length: { maximum: 255 }, uniqueness: { scope: :project_id }
    validates :reason, presence: true
    validates :summary, presence: true
    validates :duration, presence: true
    
    # Uniqueness validation for unique fields.
    validates :serial, uniqueness: { scope: :project_id }
    
    # Lock CR number after creation
    attr_readonly :project_id, :serial

    def label
      "CR #{project.label}-#{serial}"
    end

    def self.swatch
      Swatch.find_by(name: "app_theme")
    end
    
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
