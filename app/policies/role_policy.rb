class RolePolicy < ApplicationPolicy
  def role
    record
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      # App owners and admins see all roles
      return scope.all if user&.is_app_owner? || user&.is_admin?

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

    # For resource roles, we don't use the new action - access is controlled by the resource's edit view
    return false if record.is_a?(Class) && record != Role

    # For global roles, only app owners and admins can access
    user.is_app_owner? || user.has_role?(:admin)
  end

  # Only app owners can create global roles
  # Admins can create functional roles (except admin/app_owner)
  # For resource roles, the ability to create is determined by the resource's policy
  def create?
    return false unless user.present?

    # Global / functional roles
    unless role.resource.present?
      return can_manage_global_roles?
    end

    # Get the resource's policy class
    resource_policy_class = Pundit::PolicyFinder.new(role.resource).policy!

    # Create a new policy instance with the role as the record
    resource_policy = resource_policy_class.new(user_context, role)

    # For resource roles, delegate to the resource's create_role? policy if it exists, otherwise false.
    resource_policy.respond_to?(:grant_role?) && resource_policy.grant_role?
  end

  # App owners and admins can destroy any role
  # Project owners can destroy roles within their projects
  def destroy?
    return false unless user.present?

    # Global / functional roles
    unless role.resource.present?
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
      # Only app owners can create admin/app_owner roles
      if %w[admin app_owner].include?(record.name)
        return user.is_app_owner?
      end

      # Admins and app owners can create other global roles
      user.is_admin? || user.is_app_owner?
    end
end
