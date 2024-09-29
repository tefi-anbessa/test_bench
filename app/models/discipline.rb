class Discipline < ApplicationRecord
  before_save { self.code = code.upcase }
  has_many :tags

  VALID_CODE_REGEX = /[A-Z]/
  validates :code,        presence: true, length: { is: 1},
                          format: { with: VALID_CODE_REGEX },
                          uniqueness: true
  validates :name, presence: true, length: { maximum: 50 }

  def self.ransackable_attributes(auth_object = nil)
    ["code", "name"]
  end
end
