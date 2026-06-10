# frozen_string_literal: true

# Base policy for resources that belong to a project and don't belong to a discipline.
# (Discipline, ChangeManagement::Request, etc.)
# These classes cannot use the record's discipline to define required role.
# The including test must define user_is_accredited(project).
# Class must belong to project for scope association.

# Scope to current project.
class ProjectResourcePolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      if current_project.present? && 
        (user_has_project_role?(current_project) || user&.is_admin? || user&.is_app_owner?)
        scope.where(project_id: current_project.id)
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
    # Other users must have current project set in order to set scope
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
    # Including classes set the accreditation requirements.
    current_project.present? &&
      user_is_accredited?(record) &&
      record.project == current_project
  end

  def edit?
    # Protect against url injection
    return false if user.nil?
    # Content modification actions require current project to be set
    # Including classes set the accreditation requirements.
    current_project.present? &&
      user_is_accredited?(record) &&
      record.project == current_project
  end

  def update?
    # Protect against url injection
    return false if user.nil?
    # Content modification actions require current project to be set
    # Including classes set the accreditation requirements.
    current_project.present? &&
      user_is_accredited?(record) &&
      record.project == current_project
  end

  def destroy?
    # Protect against url injection
    return false if user.nil?
    # Destroy does not require global admins to have current project
    return true if user.is_admin? || user.is_app_owner?
    current_project.present? && 
      user.is_project_admin_of?(current_project) && 
      record.project == current_project
  end

  private

    def user_is_accredited?(record)
      raise NotImplementedError, "#{self.class.name} must implement user_is_accredited?"
    end
end
