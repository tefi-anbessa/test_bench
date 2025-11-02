class DisciplinePolicy < ApplicationPolicy
  def discipline
    record
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if current_project.present? && user_has_project_role?(current_project)
        scope.where(project: current_project)
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
      user_has_project_role?(current_project) && record.project == current_project
    else
      # Admin and app_owner can view when current project is nil
      user&.is_admin? || user&.is_app_owner?
    end
  end

  def show?
    # Protect against url injection
    return false if user.nil?
    if current_project.present?
      user_has_project_role?(current_project) && discipline.project == current_project
    else
      # Admin and app_owner can view when current project is nil
      user&.is_admin? || user&.is_app_owner?
    end
  end

  def new?
    # Protect against url injection
    return false if user.nil?
    if current_project.present?
      (user.is_project_manager_of?(current_project)  || user.is_admin? || user.is_app_owner?) 
    else
      # Admin and app_owner can view form when current project is nil
      user&.is_admin? || user&.is_app_owner?
    end
  end

  def create?
    # Protect against url injection
    return false if user.nil?

    if current_project.present?
      (user.is_project_manager_of?(current_project)  || user.is_admin? || user.is_app_owner?) && 
        discipline.project == current_project
    else
      # Admin and app_owner can view when current project is nil
      user&.is_admin? || user&.is_app_owner?
    end
  end

  def edit?
    update?
  end

  def update?
    # Protect against url injection
    return false if user.nil?

    if current_project.present?
      (user.is_project_manager_of?(current_project)  || user.is_admin? || user.is_app_owner?) && 
        discipline.project == current_project
    else
      # Admin and app_owner can view when current project is nil
      user&.is_admin? || user&.is_app_owner?
    end
  end
  
  def destroy?
    # Defer to application policy default
    super
  end
end
