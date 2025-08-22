class ProjectPolicy < ApplicationPolicy
  def project
    record
  end

  class Scope < ApplicationPolicy::Scope
    def resolve(scope = nil, current_project: nil)
      scope ||= self.scope
      
      if user.has_role?(:app_owner) || user.has_role?(:admin)
        # App owners and admins can see all projects
        scope.all
      elsif current_project
        # If a current project is specified, only show that project if user has access
        scope.where(id: current_project.id)
             .joins(:roles)
             .where(roles: { user_id: user.id })
      else
        # Regular users can only see projects where they have any role
        scope.joins(:roles).where(roles: { user_id: user.id }).distinct
      end
    end
  end

  def index?
    true
  end

  def show?
    true
  end

  def new?
    user.is_app_owner?
  end

  def create?
    user.is_app_owner?
  end

  def update?
    edit?
  end

  def edit?
    user.is_app_owner? || user.is_admin? || project_owner?
  end

  def destroy?
    user.present? && user.is_app_owner?
  end

  def manage_team_members?
    user.is_app_owner? || project_owner?
  end

  private

  def project_owner?
    user.has_role?(:project_owner, project) if project.persisted?
  end

  class Scope < ApplicationPolicy::Scope
    # Any project for which the user has a role can be listed.
    def resolve
      if user.is_app_owner? || user.is_admin? || 
         user.has_role?(:project_owner, :any) ||
         user.roles.where(resource_type: "Project").exists?
        # If user has global admin role, project owner role, or any project-specific role,
        # scope includes all.
        Project.all
      else
        # Scope includes the projects where user has any resource specific role
        Project.where(id: user.roles.where(resource_type: "Project").pluck(:resource_id).uniq)
      end
    end
  end
end
