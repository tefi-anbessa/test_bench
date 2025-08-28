class RolePolicy < ApplicationPolicy
  def role
    record
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      # App owners and admins see all roles
      return scope.all if user&.is_app_owner? || user&.has_role?(:admin)
      
      # For project context, show roles for that project
      if current_project.present?
        # Project owners and team members can see roles for their project
        if user.present? && (user.has_role?(:project_owner, current_project) || 
                            user.has_role?(:team_member, current_project))
          return scope.where(resource: current_project)
        end
      end
      
      # Regular users see no roles by default
      scope.none
    end
  end

  # If current project is set, all users except regular users can view roles
  # If no current project, only app owners and admins can view roles
  def index?
    if current_project.present?
      user.present? && (user.is_app_owner? || user.is_admin? || 
                       user.has_role?(:project_owner, current_project) || 
                       user.has_role?(:team_member, current_project))
    else
      user.present? && (user.is_app_owner? || user.is_admin?)
    end
  end

  # For global roles (no resource), only app owners and admins can access new form
  # For resource roles, access is controlled via the resource's show view
  def new?
    return false unless user.present?
    
    # For resource roles, we don't use the new action - access is controlled by the resource's show view
    return false if record.is_a?(Class) && record != Role
    
    # For global roles, only app owners and admins can access
    user.is_app_owner? || user.has_role?(:admin)
  end

  # Only app owners can create global roles
  # Admins can create functional roles (except admin/app_owner)
  # For resource roles, the ability to create is determined by the resource's policy
  def create?
    return false unless user.present?
    
    # For resource roles, the resource's policy will control access
    if record.is_a?(Role) && record.resource.present?
      return record.resource_policy.new(user_context, record.resource).create_role?(record.name)
    end
    
    # Check if this is a global role creation
    if record.is_a?(Class) || (record.is_a?(Role) && record.resource.nil?)
      # Only app owners can create admin or app_owner roles
      if %w[admin app_owner].include?(record.try(:name).to_s)
        return user.is_app_owner?
      end
      
      # App owners and admins can create other global roles
      return user.is_app_owner? || user.has_role?(:admin)
    end
    
    false
  end

  # App owners and admins can destroy any role
  # Project owners can destroy roles within their projects
  def destroy?
    return false unless user.present?
    
    # App owners and admins can delete any role
    return true if user.is_app_owner? || user.has_role?(:admin)
    
    # For project roles, check if the user is a project owner of the resource
    if record.resource.is_a?(Project)
      return user.has_role?(:project_owner, record.resource)
    end
    
    # For other resource roles, check if the user is a project owner of the resource's project
    if record.resource.respond_to?(:project) && record.resource.project.present?
      return user.has_role?(:project_owner, record.resource.project)
    end
    
    false
  end

  private

end
