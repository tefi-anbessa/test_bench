class CablePolicy < ResourcePolicy
  # Returns the cable record
  def cable
    record
  end
  
  # Override tag method to use cable's tag association
  def tag
    cable.tag
  end
  
  def self.required_role
    :electrical_designer
  end

  # No need to override Scope as it's already defined in ResourcePolicy
  
  # No need to override edit?/update? as the parent implementation is sufficient
  
  # No need to override user_has_project_role? as the parent implementation is sufficient
end
