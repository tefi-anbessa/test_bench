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
                        .pluck(:resource_id)).uniq
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
      user.is_admin? || 
      user.is_project_owner_of?(project)
    )
  end
  
  def destroy?
    # Only app owner can delete projects (business rule)
    user&.is_app_owner?
  end

#  def manage_team_members?
#    user.present? && (
#      user.is_app_owner? || 
#      user.has_role?(:admin) || 
#      user.has_role?(:project_owner, record)
#    )
#  end

  private

  def project_owner?
    user.present? && user.has_role?(:project_owner, record)
  end
end
