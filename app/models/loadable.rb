module Loadable
  extend ActiveSupport::Concern

  included do
    has_one :load, as: :loadable, touch: true
    accepts_nested_attributes_for :load
  end
end
