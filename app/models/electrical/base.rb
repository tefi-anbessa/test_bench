module Electrical 
  class Base < ApplicationRecord
    self.abstract_class = true
    # Add shared module behavior here
    # 
    def self.required_role
      :electrical_designer
    end

    def label
      tag&.label || I18n::t("show.orphan", model: Tag.model_name.human)
    end

    def long_label
      tag&.long_label || I18n::t("show.orphan", model: Tag.model_name.human)
    end
  end
end
