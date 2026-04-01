# frozen_string_literal: true
module DocumentControl
  class IssuePolicy < ResourcePolicy
    # Returns the resource record
    def issue
      record
    end
    
    # Inherit Scope from ResourcePolicy
    
    # Inherit all actions from ResourcePolicy
  end
end
