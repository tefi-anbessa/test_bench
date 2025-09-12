class Project < ApplicationRecord
  resourcify
  before_save { self.code = code.upcase }
  has_many :tags, dependent: :destroy
  has_many :cable_types, dependent: :destroy

  VALID_CODE_REGEX = /[A-Z][A-Z]/
  validates :code,        presence: true, length: { is: 2},
                          format: { with: VALID_CODE_REGEX },
                          uniqueness: { message: "%{model} code %{value} already exists" }
  validates :title, presence: true, length: { maximum: 50 }


  def label
      "#{code}"
  end

  def self.ransackable_attributes(auth_object = nil)
    ["code", "title", "description", "created_at", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    [ :tags ]
  end

  # Default scope for ordering projects
  scope :ordered, -> { order(:code) }

  private

end
