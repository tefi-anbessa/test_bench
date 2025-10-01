module Tagable
  extend ActiveSupport::Concern

  included do
    has_one :tag, as: :tagable, dependent: :nullify
    accepts_nested_attributes_for :tag

    # Custom validation to ensure tag is present and valid
    # validates :tag, presence: :true, if: :persisted?

  end
end
