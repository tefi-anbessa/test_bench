# frozen_string_literal: true
module ProjectChange
  class RequestPolicy < ProjectResourcePolicy

    # Define accreditation for project change requests
    # Any team member can create/edit requests (per matrix)
    def user_is_accredited?(project = current_project)
      return false if user.nil?
      user_has_project_role?(project) ||
        user.is_admin? ||
        user.is_app_owner?
    end
    
    # Inherit Scope from ResourcePolicy
    
    # Inherit all actions from ResourcePolicy
  end
end
