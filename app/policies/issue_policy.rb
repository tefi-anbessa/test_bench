# frozen_string_literal: true

class IssuePolicy < DisciplineResourcePolicy
  # Returns the resource record
  def issue
    record
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if current_project.present? &&
        (user_has_project_role?(current_project) || user&.is_admin? || user&.is_app_owner?)
        scope.joins(document: { discipline: :project })
          .where(disciplines: { project_id: current_project.id })

      elsif user&.is_admin? || user&.is_app_owner?
        scope.all

      else
        scope.none
      end
    end
  end
end
