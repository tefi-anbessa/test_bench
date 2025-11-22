
module Electrical
  class DemandPolicy < ResourcePolicy
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
      demandable&.tag
    end
    
    class Scope < ApplicationPolicy::Scope
      def resolve
        if current_project.present? && user_has_project_role?(current_project)
          # Get all demandables that belong to the current project through their tags

          scope.joins('INNER JOIN tags ON electrical_demands.demandable_type = tags.tagable_type AND 
              electrical_demands.demandable_id = tags.tagable_id')
              .joins('INNER JOIN disciplines ON tags.discipline_id = disciplines.id')
              .where(disciplines: { project_id: current_project.id })
        elsif user&.is_admin? || user&.is_app_owner?
          scope.all
        else
          scope.none
        end
      end
    end

    def new?
      # Protect against url injection
      return false if user.nil?
      if current_project.present?
        user_is_accredited?(current_project) 
      else
        # Admin and app_owner can create when current project is nil
        user&.is_admin? || user&.is_app_owner?
      end
    end

    def create?
      # Protect against url injection
      return false if user.nil?
      if current_project.present?
        user_is_accredited?(current_project) && 
          demandable&.tag&.discipline&.project == current_project
      else
        # Admin and app_owner can create when current project is nil
        user&.is_admin? || user&.is_app_owner?
      end
    end

    def update?
      # Protect against url injection
      return false if user.nil?
      if current_project.present?
        user_is_accredited?(current_project) && 
          demandable&.tag&.discipline&.project == current_project
      else
        # Admin and app_owner can create when current project is nil
        user&.is_admin? || user&.is_app_owner?
      end
    end
    # Inherit all other behavior from ResourcePolicy
  end
end