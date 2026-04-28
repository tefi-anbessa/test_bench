module Electrical
  class CableTypePolicy < ProjectResourcePolicy
    def cable_type
      record
    end

    def user_is_accredited?(project = current_project)
      electrical_discipline = Discipline.find_by(project: project, name: "Electrical")
      if electrical_discipline.nil?
        Rails.logger.error("Electrical discipline not found for project #{project&.code}")
      end

      required_role = electrical_discipline&.required_role.presence || Electrical::CableType.required_role
      user.has_role?(required_role, electrical_discipline) ||
        user.is_admin? ||
        user.is_app_owner? ||
        user.is_project_admin_of?(project)
    end
  end
end