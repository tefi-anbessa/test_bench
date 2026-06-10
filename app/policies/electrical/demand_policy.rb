
module Electrical
  class DemandPolicy < TagablePolicy
    # Returns the demand record
    def demand
      record
    end
    
    # Get the demandable object (Motor, LightCct, etc.)
    def demandable
      demand&.demandable
    end
    
    # Override tag method to use demandable's tag association
    def tag
      record.demandable&.tag
    end
    
    class Scope < ApplicationPolicy::Scope
      def resolve
        if current_project.present? && 
          (user_has_project_role?(current_project) || 
          user&.is_admin? || 
          user&.is_app_owner?)
          # Get all demandables that belong to the current project through their tags
          scope.joins('INNER JOIN tags ON electrical_demands.demandable_type = tags.tagable_type AND 
              electrical_demands.demandable_id = tags.tagable_id')
              .joins('INNER JOIN disciplines ON tags.discipline_id = disciplines.id')
              .joins('INNER JOIN projects ON disciplines.project_id = projects.id')
              .where(projects: { id: current_project.id })
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
      if current_project.present?
        # Only allow show of records on current project, if it is set
        (user_has_project_role?(current_project) || user&.is_admin? || user&.is_app_owner?) &&
          tag.project == current_project
      else
        # Admin and app_owner can view when current project is nil
        user&.is_admin? || user&.is_app_owner?
      end
    end

    def new?
      # Protect against url injection
      return false if user.nil?
      # Content modification actions require current project to be set
      return false unless current_project.present?
      # new? action is a special case for discipline scoped resources. 
      # User must have at least one discpline role to access new, or have admin role.
      user_is_accredited?(current_project) || 
        user&.is_admin? || 
        user&.is_app_owner? ||
        user&.is_project_admin_of?(current_project)
    end

    def create?
      new?
    end

    def edit?
      # Protect against url injection
      return false if user.nil?
      # Content modification actions require current project to be set
      return false unless current_project.present?
      user_is_accredited?(current_project) && tag.project == current_project
    end

    def update?
      edit?
    end

    def destroy?
      # Protect against url injection
      return false if user.nil?
      user&.is_admin? || 
      user&.is_app_owner? || 
      (user&.is_project_admin_of?(current_project) && tag.project == current_project)
    end

    private

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