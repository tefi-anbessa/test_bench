class ProjectPolicy < ApplicationPolicy
  def project
    record
  end

  class Scope < ApplicationPolicy::Scope
    def resolve(scope = nil, current_project: nil)
      scope ||= self.scope
      
      if user&.is_app_owner? || user&.has_role?(:admin)
        # App owners and admins can see all projects
        scope.all
      elsif user.present?
        # Regular users can see all projects where they have any role
        scope.with_roles([:project_owner, :team_member], user)
      else
        # Unauthenticated users see no projects
        scope.none
      end
    end
  end

  def index?
    # Only authenticated users can view the projects index
    # (actual projects are filtered by scope)
    user.present?
  end

  def show?
    # Only users with explicit access can view projects
    user.present? && (
      user.is_app_owner? ||
      user.has_role?(:admin) ||
      user.has_role?(:project_owner, record) ||
      user.has_role?(:team_member, record)
    )
  end
  
  def new?
    # Only app owners can access the new project form
    user&.is_app_owner?
  end
  
  def create?
    # Only app owners can create new projects
    user&.is_app_owner?
  end
  
  def edit?
    update?
  end
  
  def update?
    # Only app owners, admins, or project owners can update a project
    user.present? && (
      user.is_app_owner? || 
      user.has_role?(:admin) || 
      user.has_role?(:project_owner, record)
    )
  end
  
  def destroy?
    # Only app owner can delete projects (business rule)
    user&.is_app_owner?
  end

  def manage_team_members?
    user.present? && (
      user.is_app_owner? || 
      user.has_role?(:admin) || 
      user.has_role?(:project_owner, record)
    )
  end

  private

  def project_owner?
    user.present? && user.has_role?(:project_owner, record)
  end
end
