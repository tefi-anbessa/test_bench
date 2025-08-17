# frozen_string_literal: true

# This concern provides functionality for models that can have a demand (replacing Load)
module Demandable
  extend ActiveSupport::Concern
  
  included do
    # Demand association with dependent destroy
    has_one :demand, 
            as: :demandable,
            dependent: :destroy
            
    accepts_nested_attributes_for :demand
    
    # Alias for backward compatibility
    def load
      demand
    end
    
    # For form builders and other places that might call build_load
    def build_load(attributes = {})
      build_demand(attributes)
    end
    
    # For form builders and other places that might call build_demand
    def build_demand(attributes = {})
      super(attributes.merge(demandable: self))
    end
  end
end
