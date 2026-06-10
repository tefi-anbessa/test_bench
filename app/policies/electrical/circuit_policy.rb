module Electrical
  class CircuitPolicy < TagablePolicy
    class Scope < ApplicationPolicy::Scope
      def resolve
        if current_project.present? && 
            (user_has_project_role?(current_project) || 
            user&.is_admin? || 
            user&.is_app_owner?)
          scope.joins(switchboard: { tag: { discipline: :project } })
            .where(projects: { id: current_project.id })
        elsif user&.is_admin? || user&.is_app_owner?
          scope.all
        else
          scope.none
        end
      end
    end
    
  end
end