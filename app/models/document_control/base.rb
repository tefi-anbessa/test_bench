module DocumentControl
  class Base < ApplicationRecord
    self.abstract_class = true

    def self.required_role
      :document_controller
    end

    # Default discipline to reference back to this module, used in testing. 
    # Not used in the application, as projects can set their own disciplines.
    def self.discipline
      "Document Control"
    end

    def self.swatch
      Swatch.find_by(name: "app_theme")
    end
  end
end