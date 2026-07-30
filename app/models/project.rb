class Project < ApplicationRecord
  
  # === Mixins ===

  # === Constants ===

  # === Gem macros ===
  # Rolify can set roles scoped to project
  resourcify
  # Record all changes to this model's data
  has_paper_trail

  # === Attributes ===

  # === Associations ===
  belongs_to :swatch, optional: true
  has_many :disciplines, dependent: :destroy
  has_many :tags, through: :disciplines
  has_many :documents, through: :disciplines
  has_many :doc_types, through: :disciplines
  has_many :change_management_requests, dependent: :destroy

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

    def create_disciplines
      Discipline.create_all_for_project(self)
    end
end
