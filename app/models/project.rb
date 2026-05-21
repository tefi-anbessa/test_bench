class Project < ApplicationRecord
  # Gem invocation
  # Record all changes to this model's data
  has_paper_trail
  # Rolify can set roles scoped to project
  resourcify

  # Scopes
  scope :ordered, -> { order(:code) }

  # Callbacks
  before_validation { self.code = code.upcase }
  after_create :create_disciplines

  # Associations
  belongs_to :swatch, optional: true
  has_many :disciplines, dependent: :destroy
  has_many :tags, through: :disciplines
  has_many :documents, through: :disciplines
  has_many :doc_types, through: :disciplines
  has_many :change_requests, class_name: 'ProjectChange::Request', dependent: :destroy

  # Validations
  VALID_CODE_REGEX = /[A-Z][A-Z]/
  validates :code,        presence: true, length: { is: 2},
                          format: { with: VALID_CODE_REGEX },
                          uniqueness: true
  validates :title, presence: true, length: { maximum: 50 }

  # Methods
  def label
      "#{code}"
  end

  def long_label
    "#{code}: #{title}"
  end

  def self.swatch
    Swatch.find_by(name: "app_theme")
  end

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
