# frozen_string_literal: true
class DocumentPolicy < DisciplineResourcePolicy
  # Returns the resource record
  def document
    record
  end

  # Inherit all actions from DisciplineResourcePolicy

  # The base class's project-wide (class-level) branch builds
  # record.new(discipline: discipline) to probe each discipline in turn -
  # that assumes a direct, settable discipline association. Document's is
  # derived through doc_type (see Document#discipline), so this one branch
  # needs its own representative-record construction; everything else is
  # unchanged from DisciplineResourcePolicy#import?.
  def import?
    return false if user.nil?
    if record.is_a?(ApplicationRecord)
      user_is_accredited?(record) && record.project == current_project
    else
      return false if current_project.nil?
      return true if user.is_admin? || user.is_app_owner?
      Discipline.where(project_id: current_project.id).any? { |discipline| user_is_accredited?(record.new(creation_discipline: discipline)) }
    end
  end

  # Document derives discipline through doc_type (see Document#discipline),
  # not a direct column, so this can't use the base Scope's
  # where(discipline_id: ...) - same reason IssuePolicy::Scope overrides it.
  class Scope < ApplicationPolicy::Scope
    def resolve
      if current_project.present? &&
        (user_has_project_role?(current_project) || user&.is_admin? || user&.is_app_owner?)
        scope.joins(doc_type: { discipline: :project })
          .where(disciplines: { project_id: current_project.id })

      elsif user&.is_admin? || user&.is_app_owner?
        scope.all

      else
        scope.none
      end
    end
  end
end
