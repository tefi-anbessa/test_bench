class SocketCct < ApplicationRecord
  include Tagable
  include Loadable
  
  # Validations
  validates :socket_type, presence: true
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }

  private

    def self.ransackable_attributes(auth_object = nil)
      ["socket_type", "quantity", "created_at", "updated_at"]
    end

    def self.ransackable_associations(auth_object = nil)
      [ :load, :tag ]
    end
end
