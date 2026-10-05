# frozen_string_literal: true

# Base policy for resources that belong to a discipline (Tag, Document, etc.)
# Class must delegate or implement project method.
# Tagable resources have no policy of their own - every pundit call for one
# goes through this policy via its tag (TagPolicy < DisciplineResourcePolicy,
# see app/policies/tag_policy.rb), never a per-model policy.

# Scope to current project
class DisciplineResourcePolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      if current_project.present? &&
        (user_has_project_role?(current_project) || user&.is_admin? || user&.is_app_owner?)
        scope
          .where(discipline_id: Discipline.where(project_id: current_project.id))

      elsif user&.is_admin? || user&.is_app_owner?
        scope.all

      else
        scope.none
      end
    end
  end
  

  def index?
    # Protect against url injection
    return false if user.nil?
    # Global admins can see index irrespective of current project
    return true if user&.is_admin? || user&.is_app_owner?
    user_has_project_role?(current_project)
  end

  def show?
    # Protect against url injection
    return false if user.nil?
    # Global admins can see any record on any project - a deliberate exception
    # to the current-project ring fence below, kept to support the unbuilt
    # "copy from other project" workflow (see docs/DEVELOPER_NOTES.md).
    return true if user&.is_admin? || user&.is_app_owner?
    # Everyone else is restricted to the currently selected project, even if
    # they also hold a role on the record's actual project.
    record.is_a?(ApplicationRecord) &&
      current_project.present? &&
      record.project == current_project &&
      user_has_project_role?(current_project)
  end

  def new?
    # Discipline nested resources must call new? with an instance object belonging to discipline,
    # not a class.
    # Protect against url injection
    return false if user.nil?
    # Content modification actions require current project to be set
    # The controller will require current project to be set.
    user_is_accredited?(record) && record.project == current_project
  end

  def create?
    # Protect against url injection
    return false if user.nil?
    # Content modification actions require current project to be set
    # The controller will require current project to be set.
    user_is_accredited?(record) && record.project == current_project
  end

  def edit?
    # Protect against url injection
    return false if user.nil?
    # Content modification actions require current project to be set
    # The controller will require current project to be set.
    user_is_accredited?(record) && record.project == current_project
  end

  def update?
    # Protect against url injection
    return false if user.nil?
    # Content modification actions require current project to be set
    # The controller will require current project to be set.
    user_is_accredited?(record) && record.project == current_project
  end

  # Spreadsheet import (see Importable/Import::Base). A discipline-scoped
  # import already knows its discipline, so it's checked exactly like new?/
  # create? there. A project-wide import has no single discipline yet - it
  # can span several - so, called with the class itself, this instead asks
  # "is the user accredited on *any* discipline in this project", reusing
  # user_is_accredited? itself (rather than a separately-written check) so a
  # subclass's own override of it (e.g. DocTypePolicy/CableTypePolicy check
  # a document_controller role, not the discipline's generic required_role)
  # is honoured here too, not bypassed. Real per-discipline authorization
  # still happens once a project-wide file's rows (and therefore which
  # disciplines are actually involved) are resolved - see
  # Import::Base#dry_run_rows.
  def import?
    return false if user.nil?
    if record.is_a?(ApplicationRecord)
      user_is_accredited?(record) && record.project == current_project
    else
      return false if current_project.nil?
      return true if user.is_admin? || user.is_app_owner?
      Discipline.where(project_id: current_project.id).any? { |discipline| user_is_accredited?(record.new(discipline: discipline)) }
    end
  end

  def destroy?
    # Protect against url injection
    return false if user.nil?
    user&.is_admin? || 
    user&.is_app_owner? || 
    (user&.is_project_admin_of?(record.project) && record.project == current_project)
  end

  private

    # This method returns true when the user has permission for content modification actions.
    # record must respond to :discipline method
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
      # Check discipline required role first. If not defined, fall back to discipline's module required role.
      rr = record.discipline.required_role.present? ? 
          record.discipline.required_role.to_s : 
          "#{record.discipline.name}::Base".safe_constantize&.required_role.to_s
      return false unless rr
      user.has_role?(rr, record.discipline) || 
        user.is_admin? || 
        user.is_app_owner? ||
        user.is_project_admin_of?(record.project)
    end
end
