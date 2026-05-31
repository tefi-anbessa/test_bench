module Electrical
  class CableTypePolicy < DisciplineResourcePolicy
    def cable_type
      record
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
      rr = record.discipline.catalog_required_role.present? ? 
          record.discipline.catalog_required_role.to_s : 
          record.class.catalog_required_role.to_s
      return false unless rr
      user.has_role?(rr, record.discipline) || 
        user.is_admin? || 
        user.is_app_owner? ||
        user.is_project_admin_of?(record.project)
    end
  end
end