module Tagable
  extend ActiveSupport::Concern

  included do
    has_one :tag, as: :tagable, dependent: :nullify
    accepts_nested_attributes_for :tag
    delegate :project, :discipline, :label, :long_label, to: :tag
  end
end
