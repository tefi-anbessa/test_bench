module Electrical 
  class Base < ApplicationRecord
    self.abstract_class = true
    # Add shared module behavior here
    # Default accredited user role with content creation permissions
    def self.required_role
      :electrical_designer
    end

    # Default discipline for tagable models to reference back to this module
    def self.discipline_code
      "elec"
    end

    def label
      tag&.label || I18n::t("show.orphan", model: Tag.model_name.human)
    end

    def long_label
      tag&.long_label || I18n::t("show.orphan", model: Tag.model_name.human)
    end
  end
end
