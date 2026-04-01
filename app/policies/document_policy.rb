# frozen_string_literal: true
class DocumentPolicy < ResourcePolicy
  # Returns the resource record
  def document
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

  def show?
    # Protect against url injection
    return false if user.nil?
    # Only allow viewing on current project
    if current_project.present?
      user_has_project_role?(current_project) && document.discipline.project == current_project
    else
      # Admin and app_owner can view when current project is nil
      user&.is_admin? || user&.is_app_owner?
    end
  end
  
  # Inherit all other actions from ResourcePolicy
end
