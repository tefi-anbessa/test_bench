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
        # Scope includes the projects where user has any resource specific role
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
    # Admins and authenticated users with project role can view projects
    user.present? && (
      user.is_app_owner? ||
      user.is_admin? ||
      user.roles.where(resource: project).count > 0
    )
  end
  
  def new?
    # :new defers to :create
    create?
  end
  
  def create?
    # Only app owners or admins can create new projects
    user&.is_app_owner? || user&.is_admin?
  end
  
  def edit?
    update?
  end
  
  def update?
    # Only app owners, admins, or project owners can update a project
    user.present? && (
      user.is_app_owner? || 
      user.is_admin? || 
      user.is_project_manager_of?(project)
    )
  end
  
  def destroy?
    # Only app owner can delete projects (business rule)
    user&.is_app_owner?
  end

  def grant_role?
    # Implement the permissions grant policy for the project resource type
    role_name = record.name
    resource = record.resource
    allowed_roles = Role.valid_roles_for(resource.class.name)
    return false unless role_name.in?(allowed_roles)
    
    # App owners and admins can grant any valid role
    return true if user.is_app_owner? || user.is_admin?
    
    # Project managers can grant non-admin roles
    if user.has_role?(:project_manager, resource)
      return !%w[admin app_owner].include?(role_name)
    end
    
    false
  end

  def revoke_role?
    # Implement the permissions revoke policy for the project resource type
    role_name = record.name
    resource = record.resource
    allowed_roles = Role.valid_roles_for(resource.class.name)
    return false unless role_name.in?(allowed_roles)
    
    # App owners and admins can grant any valid role
    return true if user.is_app_owner? || user.is_admin?
    
    # Project managers can grant non-admin roles
    if user.has_role?(:project_manager, resource)
      return !%w[admin app_owner].include?(role_name)
    end
    
    false
  end

  private

    def project_manager?
      user.present? && user.has_role?(:project_manager, record)
    end
end
