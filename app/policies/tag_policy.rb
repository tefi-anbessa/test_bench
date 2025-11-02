class TagPolicy < ApplicationPolicy
  def tag
    record
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if current_project.present? && user_has_project_role?(current_project)
        scope.joins(:discipline).where(disciplines: { project_id: current_project.id })
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
      user_has_project_role?(current_project) && tag.discipline&.project == current_project
    else
      # Admin and app_owner can view when current project is nil
      user&.is_admin? || user&.is_app_owner?
    end
  end

  def new?
    # Protect against url injection
    return false if user.nil?
    if current_project.present?
      # Any user with project role can view tags form
      user_has_project_role?(current_project)
    else
      # Admin and app_owner can view form when current project is nil
      user&.is_admin? || user&.is_app_owner?
    end
  end

  def create?
    # Protect against url injection
    return false if user.nil?

    if current_project.present?
      user_has_project_role?(current_project) && tag.discipline&.project == current_project
    else
      # Admin and app_owner can view when current project is nil
      user&.is_admin? || user&.is_app_owner?
    end
  end

  def edit?
    # This policy is delegated to update, and is therefore not tested. 
    # If the policy is changed, be sure to write policy tests
    update?
  end

  def update?
    # Protect against url injection
    return false if user.nil?

    if current_project.present?
      user_has_project_role?(current_project) && tag.discipline&.project == current_project
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
