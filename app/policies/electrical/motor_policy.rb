module Electrical
  class MotorPolicy < ResourcePolicy
    # Returns the motor record
    def motor
      record
    end
    
    # Override tag method to use motor's tag association
    def tag
      motor.tag
    end

    def self.required_role
      :electrical_designer
    end
    
    # No need to override Scope as it's already defined in ResourcePolicy
    
    # No need to override edit?/update? as the parent implementation is sufficient
    
    # No need to override user_has_project_role? as the parent implementation is sufficient
  end
end