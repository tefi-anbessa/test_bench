module ChangeManagement
  class Base < ApplicationRecord
    self.abstract_class = true
    
    # [TODO: set roles after revamp of RBAC system]
    def self.required_role
      :designer
    end

    # Default discipline for tagable models to reference back to this module, used in testing. 
    # Not used in the application, as projects can set their own disciplines.
    # def self.discipline
    #   'Change'
    # end

    def self.swatch
      Swatch.find_by(name: "app_theme")
    end
  end
end