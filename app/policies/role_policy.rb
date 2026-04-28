class RolePolicy < ApplicationPolicy
  def role
    record
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      # App owners and admins see all roles
      return scope.all if user&.is_app_owner? || user&.is_admin?

      # For project context, show roles for that project
      if current_project.present? && user_has_project_role?(current_project)
        # Any user with a project role can see roles for their project
          return scope.where(resource: current_project)
      end

      # Regular users see no roles by default
      scope.none
    end
  end

  # If current project is set, all users with a project role can view the project roles
  # If no current project, only app owners and admins can view roles
  def index?
    # Protect against url injection
    return false if user.nil?
    if current_project.present?
      user.is_app_owner? || 
      user.is_admin? ||
      user_has_project_role?(current_project)
    else
      user.is_app_owner? || user.is_admin?
    end
  end

  # For global roles (no resource), only app owners and admins can access new form
  # For resource roles, access is controlled via the resource's show view
  def new?
    # Protect against url injection
    return false if user.nil?
    # New authorisation is only used for conditionally presenting the role assignment 
    # form on the roles index, or the create button on the roles subform.
    user.is_app_owner? || user.is_admin?
  end

  # Only app owners can create global roles
  # For resource roles, the ability to create is determined by the resource's policy
  def create?
    return false unless user.present?

    # Global / functional roles
    unless role.resource&.present?
      return can_manage_global_roles?
    end

    # Get the resource's policy class
    resource_policy_class = Pundit::PolicyFinder.new(role.resource).policy!

    # Create a new policy instance with the role as the record
    resource_policy = resource_policy_class.new(user_context, role)

    # For resource roles, delegate to the resource's grant_role? policy if it exists, otherwise false.
    resource_policy.respond_to?(:grant_role?) && resource_policy.grant_role?
  end

  # App owners and admins can destroy any role
  # Project owners can destroy roles within their projects
  def destroy?
    return false unless user.present?

    # Global / functional roles
    unless role.resource&.present?
      return can_manage_global_roles?
    end

    # Get the resource's policy class
    resource_policy_class = Pundit::PolicyFinder.new(role.resource).policy!

    # Create a new policy instance with the role as the record
    resource_policy = resource_policy_class.new(user_context, role)

    # For resource roles, delegate to the resource's revoke_role? policy if it exists, otherwise false.
    resource_policy.respond_to?(:revoke_role?) && resource_policy.revoke_role?
  end

  private
    def can_manage_global_roles?
      # Only app owners can create admin/app_owner/project_admin roles
      if %w[admin app_owner project_admin].include?(record.name)
        return user.is_app_owner?
      end

      # Admins and app owners can create other global and resource wide roles
      user.is_admin? || user.is_app_owner?
    end
end
