# frozen_string_literal: true

class DocTypePolicy < DisciplineResourcePolicy

  # doc_types.discipline_id is a direct column, so the inherited
  # DisciplineResourcePolicy::Scope already produces the correct query.

  # Doc types are only ever meant to be browsed by someone accredited to
  # manage them (or an admin) - never a generic project role, unlike most
  # other discipline resources (see docs/ROLES_AND_PERMISSIONS.md). A
  # document_controller grant can sit at either the project or the
  # discipline level, and the two index views need gating separately: a
  # discipline-scoped grant is enough for that one discipline's index, but
  # not for the project-wide one spanning every other discipline too.
  # Called with the actual Discipline/Project being indexed (see
  # DocTypesController#index), not the bare class - that's what lets the
  # two cases be told apart at all.
  def index?
    return false if user.nil?
    case record
    when Discipline
      user.has_role?(:document_controller, record) ||
        user.has_role?(:document_controller, record.project) ||
        user.is_project_admin_of?(record.project) ||
        user.is_admin? || user.is_app_owner?
    when Project
      user.has_role?(:document_controller, record) ||
        user.is_project_admin_of?(record) ||
        user.is_admin? || user.is_app_owner?
    else
      false
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

