class SwitchboardPolicy < ElectricalResourcePolicy
  # Returns the switchboard record
  def switchboard
    record
  end
  
  # Override tag method to use switchboard's tag association
  def tag
    switchboard.tag
  end
  
  # No need to override Scope as it's already defined in ElectricalResourcePolicy
  
  # No need to override edit?/update? as the parent implementation is sufficient
  
  # No need to override user_has_project_role? as the parent implementation is sufficient
end
