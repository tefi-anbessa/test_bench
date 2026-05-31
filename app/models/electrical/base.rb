module Electrical 
  class Base < ApplicationRecord
    self.abstract_class = true
    # Add shared module behavior here
    # Default accredited user role with content creation permissions
    def self.required_role
      :designer
    end

    def self.catalog_required_role
      :custodian
    end

    # Default discipline for tagable models to reference back to this module, used in testing. 
    # Not used in the application, as projects can set their own disciplines.
    def self.discipline
      "Electrical"
    end

    def self.swatch
      Swatch.find_by(name: "Electrical")
    end
  end
end
