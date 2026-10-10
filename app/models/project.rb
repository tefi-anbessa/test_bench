class Project < ApplicationRecord
  
  # === Mixins ===

  # === Constants ===

  # === Gem macros ===
  # Rolify can set roles scoped to project
  resourcify
  # Record all changes to this model's data
  has_paper_trail

  # === Attributes ===
  # Not persisted - the discipline codes chosen on the new-project form (see
  # ProjectsController#create). Read once, by create_disciplines, right
  # after this project is created.
  attr_accessor :discipline_codes

  # === Associations ===
  belongs_to :swatch, optional: true
  has_many :disciplines, dependent: :destroy
  has_many :tags, through: :disciplines
  has_many :documents, through: :disciplines
  has_many :doc_types, through: :disciplines
  has_many :electrical_cable_types, through: :disciplines
  has_many :change_management_requests, class_name: "ChangeManagement::Request", dependent: :destroy

  # === Scopes ===
  scope :ordered, -> { order(:code) }

  # === Validations ===
  VALID_CODE_REGEX = /[A-Z][A-Z]/
  validates :code,        presence: true, length: { is: 2},
                          format: { with: VALID_CODE_REGEX },
                          uniqueness: true
  validates :title, presence: true, length: { maximum: 50 }

  # === Callbacks ===
  before_validation { self.code = code.upcase }
  after_create :create_disciplines

  # === Class methods ===
  def self.swatch
    Swatch.find_by(name: "app_theme")
  end
  
  # === Class methods - Queries ===
  # Provide SQL for ordering projects in the navigator
  def self.navigator_order_sql
    "projects.code ASC"
  end

  # === Public methods ===
  def label
      "#{code}"
  end

  def long_label
    "#{code}: #{title}"
  end

  # === Private methods ===

  private

    def self.ransackable_attributes(auth_object = nil)
      ["code", "title", "description", "created_at", "updated_at"]
    end

    def self.ransackable_associations(auth_object = nil)
      [ :disciplines, :tags, :electrical_cable_types ]
    end

    # Only the disciplines explicitly chosen on the new-project form - see
    # Discipline.create_selected_for_project. A project with none selected
    # (e.g. created outside the form, from a test or the console) simply
    # starts with none; disciplines can always be added individually later.
    def create_disciplines
      Discipline.create_selected_for_project(self, codes: discipline_codes || [])
    end
end
