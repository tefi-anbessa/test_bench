module Instrument
  class Base < ApplicationRecord
    self.abstract_class = true
    # Add shared module behavior here
    
    def self.required_role
      :designer
    end

    def self.catalog_required_role
      :custodian
    end

    def label
      "define default label in app/models/instrument/base.rb"
    end

    def long_label
      "define default long_label in app/models/instrument/base.rb"
    end

    def self.swatch
      Swatch.find_by(name: "Instrument") || Swatch.find_by(name: "app_theme")
    end
  end
end