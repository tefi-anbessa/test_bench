# frozen_string_literal: true

class DisciplinePolicy < ProjectResourcePolicy
  def discipline
    record
  end

  def user_is_accredited?(project = current_project)
    user.is_project_manager_of?(project)  ||
      user.is_project_admin_of?(project) ||
      user.is_admin? || user.is_app_owner?
  end

  # Disciplines are auto-created and cannot be created/destroyed by project managers
  # Only admins can create or destroy disciplines
  # Current project must be set
  def create?
    return false if user.nil?
    return false if current_project.nil?
      user.is_admin? || 
      user.is_app_owner? || 
      ( user.is_project_admin_of?(discipline.project) && 
        discipline.project == current_project )
  end

  def destroy?
    return false if user.nil?
    return false if current_project.nil?
      user.is_admin? || 
      user.is_app_owner? || 
      ( user.is_project_admin_of?(discipline.project) && 
        discipline.project == current_project )
  end

  # The role policy delegates to grant_role? for create action on roles resourced to Discipline instance
  def grant_role?
    # Protect against url injection and ensure this is only used for resource-scoped roles
    return false if user.nil?
    return false if record.resource.nil?
    # Implement the permissions grant policy for resources
    role_name = record.name
    resource = record.resource
    allowed_roles = Role.valid_roles_for(resource.class.name)
    return false unless role_name.in?(allowed_roles)
    
    # App owner can grant any valid role
    return true if user.is_app_owner?
    
    # Project managers and admins can grant non-admin roles
    # Project manager is restricted to roles on current project
    if (resource.project == current_project && 
          user.is_project_manager_of?(resource.project)) || 
          user.is_admin?
      return !%w[admin app_owner project_admin].include?(role_name)
    end
    
    false
  end

  # The role policy delegates to revoke_role? for destroy action on roles resourced to Discipline instance
  def revoke_role?
    # Protect against url injection and ensure this is only used for resource-scoped roles
    return false if user.nil?
    return false if record.resource.nil?
    # Implement the permissions revoke policy for the resource type
    role_name = record.name
    resource = record.resource
    allowed_roles = Role.valid_roles_for(resource.class.name)
    return false unless role_name.in?(allowed_roles)
    
    # App owner can revoke any valid role
    return true if user.is_app_owner?
    
    # Project managers can revoke non-admin roles
    if user.has_role?(:project_manager, resource.project) || user.is_admin?
      return !%w[admin app_owner project_admin].include?(role_name)
    end
    
    false
  end
end
