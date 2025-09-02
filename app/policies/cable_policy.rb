class CablePolicy < ElectricalResourcePolicy
  # Returns the cable record
  def cable
    record
  end
  
  # Override tag method to use cable's tag association
  def tag
    cable.tag
  end
  
  # No need to override Scope as it's already defined in ElectricalResourcePolicy
  
  # No need to override edit?/update? as the parent implementation is sufficient
  
  # No need to override user_has_project_role? as the parent implementation is sufficient
end
