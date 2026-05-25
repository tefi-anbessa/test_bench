module Tagable
  extend ActiveSupport::Concern

  included do
    has_one :tag, as: :tagable, dependent: :nullify
    accepts_nested_attributes_for :tag
    delegate :project, :stage, :discipline, :label, :long_label, :service, :location, to: :tag, allow_nil: true
  end
end
