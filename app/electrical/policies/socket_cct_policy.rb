class SocketCctPolicy < ResourcePolicy
  # Returns the socket_cct record
  def socket_cct
    record
  end
  
  # Override tag method to use socket_cct's tag association
  def tag
    socket_cct.tag
  end

  def self.required_role
    :electrical_designer
  end
  
  # No need to override Scope as it's already defined in ResourcePolicy
  
  # No need to override edit?/update? as the parent implementation is sufficient
  
  # No need to override user_has_project_role? as the parent implementation is sufficient
end
