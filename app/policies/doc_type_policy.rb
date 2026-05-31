# frozen_string_literal: true

class DocTypePolicy < DisciplineResourcePolicy

  class Scope < ApplicationPolicy::Scope
    def resolve
      if current_project.present? && 
        (user_has_project_role?(current_project) || user&.is_admin? || user&.is_app_owner?)
          scope.joins(:discipline).where(disciplines: { project_id: current_project.id })
      elsif user&.is_admin? || user&.is_app_owner?
        scope.all
      else
        scope.none
      end
    end
  end

  # Override index? from DisciplineResourcePolicy
  # Only doc controllers and admins need to see the doc type index
  def index?
    # Protect against url injection
    return false if user.nil?
    return true if user&.is_admin? || user&.is_app_owner?
    if record.is_a?(DocType)
      (user.has_role?(:document_controller, record.discipline) || 
        user.has_role?(:document_controller, record.discipline.project) || 
        user.is_project_admin_of?(record.project))
    # When discipline is not available, use current project to determine permission
    elsif record == DocType
      user.has_role?(:document_controller, current_project) || 
        user.is_project_admin_of?(current_project)
    end
  end

  private

    def user_is_accredited?(record)
      # Doc type requires a discipline to determine permissions, so policy is only 
      # available on instance records, not on class.
      # The rails logger message is only for development transition phase.
      unless record.is_a?(ApplicationRecord)
        Rails.logger.warn "Policy Error: #{record.class} called with class instead of instance. " \
                        "Use an instance variable with discipline association."
        return false
      end
      user&.is_admin? || 
        user&.is_app_owner? || 
        user.has_role?(:document_controller, record.discipline) || 
        user.has_role?(:document_controller, record.discipline.project) || 
        user.is_project_admin_of?(record.project)
    end
end

