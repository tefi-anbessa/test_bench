class RolePolicy < ApplicationPolicy
  def role
    record
  end

  class Scope < ApplicationPolicy::Scope
    attr_reader :project

    def resolve
      if user&.is_app_owner? || user&.has_role?(:admin)
        scope.all
      elsif current_project.present?
        # Show roles for the current project
        scope.where(resource: current_project)
      else
        scope.none
      end
    end
  end

  # Anyone can view the roles index if a project is selected
  def index?
    current_project.present?
  end

  # Only app owners can view the new role form
  def new?
    user.present? && user.is_app_owner?
  end

  # Only app owners can create new roles
  def create?
    user.present? && user.is_app_owner?
  end

  # Only app owners can destroy roles
  def destroy?
    user.present? && user.is_app_owner?
  end

  private

end
