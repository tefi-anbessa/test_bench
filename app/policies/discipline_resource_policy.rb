# frozen_string_literal: true

# Base policy for resources that belong to a discipline (Tag, Document, etc.)
# Class must delegate or implement project method.
# Tagable resources should inherit from TagablePolicy.

# Scope to current project
class DisciplineResourcePolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      if current_project.present? &&
        (user_has_project_role?(current_project) || user&.is_admin? || user&.is_app_owner?)
        scope
          .where(discipline_id: Discipline.where(project_id: current_project.id))
          .includes(:discipline)

      elsif user&.is_admin? || user&.is_app_owner?
        scope.includes(:discipline)

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
    # Global admins can see any record
    return true if user&.is_admin? || user&.is_app_owner?
    # User should have a role on the record's project
    record.is_a?(ApplicationRecord) &&
      user_has_project_role?(record.project)
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
