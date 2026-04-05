# frozen_string_literal: true
module ProjectChange
  class RequestPolicy < ProjectResourcePolicy
    # Returns the resource record
    def request
      record
    end
    
    # Inherit Scope from ResourcePolicy
    
    # Inherit all actions from ResourcePolicy
  end
end
