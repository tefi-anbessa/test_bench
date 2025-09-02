class CircuitPolicy < ElectricalResourcePolicy
  # Returns the circuit record
  def circuit
    record
  end
  
  # Get the parent switchboard
  def switchboard
    circuit.switchboard
  end

  # Override tag method to use switchboard's tag association
  def tag
    switchboard&.tag
  end
  
  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless current_project
      
      # Get all circuits where the parent switchboard's tag is associated with the current project
      scope.joins(switchboard: :tag).where(tags: { project: current_project })
    end
  end
  
  # Inherit all other behavior from ElectricalResourcePolicy
end
