# Shared behavior for CableType's delegated detail classes (e.g.
# Electrical::CableTypeDetail, Instrument::CableTypeDetail) - each holds
# only the discipline-specific attributes that aren't shared on CableType
# itself. Mirrors Tagable's own shape: the inverse side of a
# delegated_type has no columns of its own, just a has_one back to the
# owner.
module CableTypeDetailable
  extend ActiveSupport::Concern

  included do
    has_one :cable_type, as: :detail, dependent: :nullify
    has_one :discipline, through: :cable_type
    has_one :project, through: :discipline
    delegate :label, :long_label, :code, to: :cable_type, allow_nil: true
  end
end
