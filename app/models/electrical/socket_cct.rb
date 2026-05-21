module Electrical
  class SocketCct < Base
    include Tagable
    include Electrical::Demandable
    include TagableNavigation
    
    enum :socket_type, Constants.electrical.socket_cct.socket_type.to_h

    # Validations
    validates :socket_type, presence: true
    validates :quantity, numericality: { only_integer: true, greater_than: 0 }

    private

      def self.ransackable_attributes(auth_object = nil)
        ["socket_type", "quantity", "notes", "created_at", "updated_at"]
      end

      def self.ransackable_associations(auth_object = nil)
        [ :electrical_demand, :tag, :tag_discipline, :tag_discipline_project ]
      end
  end
end