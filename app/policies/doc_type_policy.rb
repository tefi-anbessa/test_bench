# frozen_string_literal: true

class DocTypePolicy < DisciplineResourcePolicy

  # doc_types.discipline_id is a direct column, so the inherited
  # DisciplineResourcePolicy::Scope already produces the correct query.

  # Override index? from DisciplineResourcePolicy
  # Only doc controllers and admins need to see the doc type index
  def index?
    # Protect against url injection
    return false if user.nil?
    return false if current_project.nil?
    if record.is_a?(DocType)
      record.project == current_project &&
        (user.has_role?(:document_controller, record.discipline) ||
          user.has_role?(:document_controller, record.discipline.project) ||
          user.is_project_admin_of?(record.project) ||
          user.is_admin? || user.is_app_owner?)
    # When discipline is not available, use current project to determine permission
    elsif record == DocType
      user.has_role?(:document_controller, current_project) ||
        user.is_project_admin_of?(current_project) ||
        user.is_admin? || user.is_app_owner?
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

