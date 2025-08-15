class Discipline < ApplicationRecord
  # Define standard disciplines as a constant
  DISCIPLINES = [
    { code: 'A', name: 'Administration' },
    { code: 'B', name: 'Architecture' },
    { code: 'C', name: 'Civil Engineering' },
    { code: 'E', name: 'Electrical Engineering' },
    { code: 'I', name: 'Information Tech' },
    { code: 'J', name: 'Instrument Engineering' },
    { code: 'M', name: 'Mechanical Engineering' },
    { code: 'P', name: 'Process Engineering' },
    { code: 'U', name: 'Multi-Discipline' }
  ].freeze

  before_save { self.code = code.upcase }
  has_many :tags, dependent: :destroy

  VALID_CODE_REGEX = /[A-Z]/
  validates :code,        presence: true, length: { is: 1},
                          format: { with: VALID_CODE_REGEX },
                          uniqueness: true
  validates :name, presence: true, length: { maximum: 50 }

  def self.ransackable_attributes(auth_object = nil)
    ["code", "name"]
  end
end
