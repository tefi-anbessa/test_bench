class CableTypePolicy < ApplicationPolicy
  def cable_type
    record
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless @current_project
      scope.where(project: @current_project)
    end
  end

  def index?
    # Admin and app_owner can view anything
    return true if user&.is_admin? || user&.is_app_owner?
    
    # Others can only view if they have a project role
    current_project.present? && user_has_project_role?
  end

  def show?
    # Admin and app_owner can view anything
    return true if user&.is_admin? || user&.is_app_owner?
    
    # Others can only view if they have a project role and the cable type belongs to the current project
    return false unless user && current_project && cable_type
    user_has_project_role? && cable_type.project == current_project
  end
  
  def new?
    create?
  end
  
  def create?
    # Protect against url injection
    return false if user.nil? || current_project.nil?

    # Admin and app_owner can create
    return true if user.is_admin? || user.is_app_owner?
    
    # Other than admins, only electrical designers in the project can create cable types
    return user.has_role?(:electrical_designer) && user_has_project_role?
  end
  
  def edit?
    update?
  end
  
  def update?
    create?
  end
  
  def destroy?
    # Defer to application policy default
    super
  end
end
