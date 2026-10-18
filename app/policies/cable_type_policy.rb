class CableTypePolicy < DisciplineResourcePolicy
  def cable_type
    record
  end

  # Cable types are catalog/reference data, deliberately gated by a
  # narrower, dedicated role rather than the discipline's generic
  # required_role (see docs/ROLES_AND_PERMISSIONS.md) - not open to every
  # project role like a typical discipline resource's index. Unlike
  # DocType's document_controller, that role is itself configured per
  # discipline (catalog_required_role), so there's no single role name to
  # check for a project-wide grant - a discipline-scoped custodian only
  # ever sees that one discipline's index, never the project-wide one.
  # Called with the actual Discipline/Project being indexed (see
  # CableTypesController#index), not the bare class - that's what lets the
  # two cases be told apart at all.
  def index?
    return false if user.nil?
    case record
    when Discipline
      rr = record.catalog_required_role.presence || record.default_catalog_required_role
      (rr.present? && user.has_role?(rr, record)) ||
        user.is_project_admin_of?(record.project) ||
        user.is_admin? || user.is_app_owner?
    when Project
      user.is_project_admin_of?(record) ||
        user.is_admin? || user.is_app_owner?
    else
      false
    end
  end

  private

    # Override discipline policy to use catalog_required_role, for catalog model types.
    def user_is_accredited?(record)
      # Ensure record is an instance, not a class.
      # The rails error is only for development transition phase.
      unless record.is_a?(ApplicationRecord)
        unless Rails.env.production?
          raise "Policy Error: #{record.class} called with class instead of instance. " \
                "Use an instance variable with discipline association."
        end
        return false
      end
      rr = record.discipline.catalog_required_role.presence ||
          record.discipline.default_catalog_required_role
      return false unless rr
      user.has_role?(rr, record.discipline) ||
        user.is_admin? ||
        user.is_app_owner? ||
        user.is_project_admin_of?(record.project)
    end
end
