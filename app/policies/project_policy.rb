class ProjectPolicy < ApplicationPolicy
  def project
    record
  end

  class Scope < ApplicationPolicy::Scope
    def resolve(scope = nil, current_project: nil)
      scope ||= self.scope
      
      if user.is_app_owner? || user.is_admin? ||
        user.roles.where(resource_type: "Project", resource_id: nil).count > 0
        # If user has global admin role, or any resource wide role on Projects,
        # scope includes all.
        scope.all
      else
        # Scope includes the projects where user has any role
        scope.where(:id => user.roles.where(resource_type: "Project")
                        .pluck(:resource_id).uniq)
      end

    end
  end

  def index?
    # Authenticated users can view the projects index
    # (actual projects are filtered by scope)
    user.present?
  end

  def show?
    # Protect against url injection
    return false if user.nil?
    # Admins and authenticated users with project role can view projects
    user_has_project_role?(project) || user&.is_admin? || user&.is_app_owner?
  end
  
  def new?
    # Protect against url injection
    return false if user.nil?
    # Only app owners or admins can access the new project form
    user&.is_app_owner? || user&.is_admin?
  end
  
  def create?
    # Protect against url injection
    return false if user.nil?
    # Only app owners or admins can create new projects
    user.is_app_owner? || user&.is_admin?
  end
  
  def edit?
    # Protect against url injection
    return false if user.nil?
    # Only app owners, admins, project managers and project admins can access the edit project form
    user.is_app_owner? || 
      user.is_admin? || 
      user.is_project_manager_of?(project) ||
      user.is_project_admin_of?(project)
  end
  
  def update?
    # Protect against url injection
    return false if user.nil?
    # Only app owners, admins, project managers and project admins can update a project
      user.is_app_owner? || 
      user.is_admin? || 
      user.is_project_manager_of?(project) ||
      user.is_project_admin_of?(project)
  end
  
  def destroy?
    # Protect against url injection
    return false if user.nil?
    # Only app owner can delete projects (business rule)
    user.is_app_owner?
  end

  # The role policy delegates to grant_role? for create action on roles resourced to Project instance
  def grant_role?
    # Protect against url injection and ensure this is only used for resource-scoped roles
    return false if user.nil?
    return false if record.resource.nil?
    # Implement the permissions grant policy for resources (only implemented for projects)
    role_name = record.name
    resource = record.resource
    allowed_roles = Role.valid_roles_for(resource.class.name)
    return false unless role_name.in?(allowed_roles)
    
    # App owner can grant any valid role
    return true if user.is_app_owner?
    
    # Project managers and admins can grant non-admin roles
    # Project manager is restricted to roles on current project
    if (resource == current_project && user.is_project_manager_of?(resource)) || 
       user.is_admin?
      return !%w[admin app_owner project_admin].include?(role_name)
    end
    
    false
  end

  # The role policy delegates to revoke_role? for destroy action on roles resourced to Project instance
  def revoke_role?
    # Protect against url injection and ensure this is only used for resource-scoped roles
    return false if user.nil?
    return false if record.resource.nil?
    # Implement the permissions revoke policy for the project resource type
    role_name = record.name
    resource = record.resource
    # Allow destroy of invalid roles in case it is useful. Hard to test...
    # allowed_roles = Role.valid_roles_for(resource.class.name)
    # return false unless role_name.in?(allowed_roles)
    
    # App owner can revoke any valid role
    return true if user.is_app_owner?
    
    # Project managers can revoke non-admin roles
    if user.has_role?(:project_manager, resource) || user.is_admin?
      return !%w[admin app_owner project_admin].include?(role_name)
    end
    
    false
  end

  private

    def project_manager?
      user.present? && user.has_role?(:project_manager, record)
    end
end
