class CableType < ApplicationRecord
  resourcify
  has_many :cables, dependent: :destroy
  enum :temperature_rating, Constants.electrical.temperature_rating.each_with_index.to_h
  validates :conductor_makeup, presence: true

  private


    def self.ransackable_attributes(auth_object = nil)
      ["conductor_material", "conductor_makeup", "csa", "description",
        "neutral_csa", "earth_csa", "insulation", "bedding", "armour",
        "bedding", "sheath", "bedding_od", "overall_od", "temperature_rating",
        "created_at", "updated_at"]
    end


    def self.ransackable_associations(auth_object = nil)
      ["cables"]
    end

end
