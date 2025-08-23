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
    # Anyone can view the projects index (actual projects are filtered by scope)
    true
  end

  def show?
    # Anyone can view a project if they know the URL
    # Actual authorization is handled by the scope
    true
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
    # Only app owners and admins can delete projects
    # Project owners cannot delete projects (business rule)
    user.present? && (user.is_app_owner? || user.has_role?(:admin))
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
