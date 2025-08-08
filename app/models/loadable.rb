module Loadable
  extend ActiveSupport::Concern

  included do
    has_one :load, as: :loadable, dependent: :destroy
    accepts_nested_attributes_for :load
  end
end
