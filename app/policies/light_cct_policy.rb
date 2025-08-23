class LightCctPolicy < ApplicationPolicy
  # Returns the light_cct record
  def light_cct
    record
  end

  # Required functional role to access light circuits
  def self.required_role
    :electrical_designer
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user&.is_app_owner? || user&.is_admin?
        scope.all
      elsif user.present? && current_project.present? && user_has_project_role?
        # Get all light circuits that are tagged with the current project
        scope.includes(tag: :project).where(tag: { project: current_project })
      else
        scope.none
      end
    end

    private

    def user_has_project_role?
      user.roles
          .where(resource: current_project)
          .exists?
    end
  end

  def index?
    # Any authenticated user can view the light circuits index
    # (actual light circuits are filtered by scope based on project membership)
    user.present?
  end

  def show?
    return false unless user.present? && record.present?
    
    # Admins and app owners can view any light circuit
    return true if user.is_app_owner? || user.is_admin?
    
    # Check if record is in scope for the current user
    LightCctPolicy::Scope.new(user_context, LightCct).resolve.exists?(id: record.id)
  end

  def new?
    create?
  end

  def create?
    return false unless user.present? && current_project.present?
    
    # Admins and app owners can create any light circuit
    return true if user.is_app_owner? || user.is_admin?
    
    # Check if user has the required functional role
    has_required_role = user.has_role?(self.class.required_role)
    
    # Check if user has a role on the current project
    has_required_role && user_has_project_role?(current_project)
  end

  def edit?
    update?
  end

  def update?
    return false unless user.present? && record.present?
    
    # Admins and app owners can update any light circuit
    return true if user.is_app_owner? || user.is_admin?
    
    # Check if user has the required functional role
    return false unless user.has_role?(self.class.required_role)
    
    # Check if record is in scope for the current user
    LightCctPolicy::Scope.new(user_context, LightCct).resolve.exists?(id: record.id)
  end

  # destroy? is inherited from ApplicationPolicy which defaults to admin and app_owner only
  # No need to check scope since only admins/app_owners can destroy

  private

  def user_has_project_role?(project)
    return false if user.nil? || project.nil?
    
    # Check if user has any role on the project
    user.roles
        .where(resource: project)
        .exists? || 
    # Or if user has a global role
    user.roles
        .where(resource: nil)
        .where(name: %w[admin app_owner])
        .exists?
  end
end
