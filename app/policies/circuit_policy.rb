class CircuitPolicy < ElectricalResourcePolicy
  # Returns the circuit record
  def circuit
    record
  end
  
  # Get the parent switchboard
  def switchboard
    circuit.switchboard
  end
  
  # Scope for circuits required to reference the switchboard tag.
  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.all if user&.is_admin? || user&.is_app_owner?
      return scope.none unless current_project
      scope.joins(switchboard: :tag).where(tags: { project: current_project })
    end
  end



  # Inherit all other behavior from ElectricalResourcePolicy
end
