module Electrical
  class HeaterPolicy < ResourcePolicy
    # Returns the resource record
    def heater
      record
    end
    
    # Override tag method to use resource's tag association
    def tag
      heater.tag
    end
    
    # Inherit Scope from ResourcePolicy
    
    # Inherit all actions from ResourcePolicy
  end
end