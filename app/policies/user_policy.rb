class UserPolicy < ApplicationPolicy
  # NOTE: Up to Pundit v2.3.1, the inheritance was declared as
  # `Scope < Scope` rather than `Scope < ApplicationPolicy::Scope`.
  # In most cases the behavior will be identical, but if updating existing
  # code, beware of possible changes to the ancestors:
  # https://gist.github.com/Burgestrand/4b4bc22f31c8a95c425fc0e30d7ef1f5

  class Scope < ApplicationPolicy::Scope
    def resolve
      if current_project.present? && user_has_project_role?(current_project)
      # Get all users with any role on the current project
      user_ids = User.joins(:roles).where(roles: 
      { resource_type: 'Project', resource_id: current_project.id }).pluck(:id)
      # Add admins and super admins
      user_ids += User.joins(:roles).where(name: ['admin', 'app_owner']).pluck(:id)
      scope.where(id: user_ids.uniq)
      elsif user&.is_admin? || user&.is_app_owner?
        scope.all
      else
        scope.where(id: user&.id)  # Only the current user
      end
    end
  end

  def index?
    # Protect against url injection, rely on scope
    !user.nil?
  end

  def show?
    # Protect against url injection, rely on scope
    !user.nil?
  end
end
