module Electrical
  class CableTypePolicy < DisciplineResourcePolicy
    def cable_type
      record
    end

    def user_is_accredited?(project = current_project)
      # If record is a class, use class required_role
      # If record is an instance, use discipline required_role with fallback to class required_role
      required_role = if record.is_a?(Class)
                        record.required_role
                      else
                        record.discipline&.required_role.presence || record.class.required_role
                      end

      discipline = record.is_a?(Class) ? nil : record.discipline

      user.has_role?(required_role, discipline) ||
        user.is_admin? ||
        user.is_app_owner? ||
        user.is_project_admin_of?(project)
    end
  end
end