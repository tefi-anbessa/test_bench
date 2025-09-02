class TagPolicy < ApplicationPolicy
  def tag
    record
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless @current_project
      scope.where(project: @current_project)
    end

  end

  def index?
    # Admin and app_owner can view index
    return true if user&.is_admin? || user&.is_app_owner?
    # Any user with a role on the project can view tag index
    current_project.present? && user_has_project_role?
  end

  def show?
    # Admin and app_owner can view anything
    return true if user&.is_admin? || user&.is_app_owner?
    
    # Others can only view if they have a project role and the cable type belongs to the current project
    return false unless user && current_project && tag
    user_has_project_role? && tag.project == current_project
  end

  def new?
    create?
  end

  def create?
    # Protect against url injection
    return false if user.nil? || current_project.nil?
    # Admin and app_owner can create
    return true if user&.is_admin? || user&.is_app_owner?
    # Any user with a role on the project can create tags
    current_project.present? && user_has_project_role?
  end

  def edit?
    update?
  end

  def update?
    # Protect against url injection
    return false if user.nil? || current_project.nil?
    # Admin and app_owner can update
    return true if user&.is_admin? || user&.is_app_owner?
    # Any user with a role on the project can update tags
    current_project.present? && user_has_project_role?
  end
  
  def destroy?
    # Defer to application policy default
    super
  end


end
