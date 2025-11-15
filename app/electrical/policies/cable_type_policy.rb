class CableTypePolicy < ApplicationPolicy
  def cable_type
    record
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if current_project.present? && user_has_project_role?(current_project)
        scope.joins(:project).where(project_id: current_project.id)
      elsif user&.is_admin? || user&.is_app_owner?
        scope.all
      else
        scope.none
      end
    end
  end

  def index?
    # Protect against url injection
    return false if user.nil?
    if current_project.present?
      user_has_project_role?(current_project)
    else
      # Admin and app_owner can view when current project is nil
      user&.is_admin? || user&.is_app_owner?
    end
  end

  def show?
    # Protect against url injection
    return false if user.nil?
    if current_project.present?
      user_has_project_role?(current_project) && record.project == current_project
    else
      # Admin and app_owner can view when current project is nil
      user&.is_admin? || user&.is_app_owner?
    end
  end
  
  def new?
    create?
  end

  def create?
    # Protect against url injection
    return false if user.nil?
    if current_project.present?
       (user_has_project_role?(current_project) && 
        user.has_role?(CableType.required_role)) || user.is_admin? || user.is_app_owner?
    else
      # Admin and app_owner can create when current project is nil
      user&.is_admin? || user&.is_app_owner?
    end
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
