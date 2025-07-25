
module Tagable
  extend ActiveSupport::Concern

  included do
    has_one :tag, as: :tagable, touch: true, dependent: :nullify
    accepts_nested_attributes_for :tag
  end
end
