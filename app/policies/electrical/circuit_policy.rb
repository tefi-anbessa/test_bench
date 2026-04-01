module Electrical
  class CircuitPolicy < TagablePolicy
    # Returns the circuit record
    def circuit
      record
    end
    
    def self.required_role
      Electrical::Circuit.required_role
    end

    class Scope < ApplicationPolicy::Scope
      def resolve
        if current_project.present? && user_has_project_role?(current_project)
          scope.joins(electrical_switchboard: { tag: { discipline: :project } })
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
      user_has_project_role?(current_project) && circuit&.electrical_switchboard&.tag&.discipline&.project == current_project
    else
      # Admin and app_owner can view when current project is nil
      user&.is_admin? || user&.is_app_owner?
    end
  end

    def create?
      # Protect against url injection
      return false if user.nil?
      if current_project.present?
        user_is_accredited?(current_project)
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
          circuit&.electrical_switchboard&.tag&.discipline&.project == current_project
      else
        # Admin and app_owner can update when current project is nil
        user&.is_admin? || user&.is_app_owner?
      end
    end
  # Inherit all other behavior from ResourcePolicy
  end
end