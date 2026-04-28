# frozen_string_literal: true

# Base policy for resources that belong to a project and don't belong to a discipline.
# (Discipline, CableType, LineType etc.)
# These classes cannot use the discipline to define required role.
# The including test must define user_is_accredited(project).
# Class must belong to project for scope association.

class ProjectResourcePolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      if current_project.present? && 
        (user_has_project_role?(current_project) || user&.is_admin? || user&.is_app_owner?)
        scope.joins(:project).where(projects: { id: current_project.id })
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
    current_project.present? && user_has_project_role?(current_project)
  end

  def show?
    # Protect against url injection
    return false if user.nil?
    if current_project.present?
      # Only allow show of records on current project, if it is set
      (user_has_project_role?(current_project) || user&.is_admin? || user&.is_app_owner?) &&
        record.project == current_project
    else
      # Global admins can view when current project is nil
      user&.is_admin? || user&.is_app_owner?
    end
  end

  def new?
    # Protect against url injection
    return false if user.nil?
    # Content modification actions require current project to be set
    # Including classes set the accreditation requirements.
    current_project.present? &&
      user_is_accredited?(current_project)
  end

  def create?
    # Protect against url injection
    return false if user.nil?
    # Content modification actions require current project to be set
    # Including classes set the accreditation requirements.
    current_project.present? &&
      user_is_accredited?(current_project) &&
      record.project == current_project
  end

  def edit?
    # Protect against url injection
    return false if user.nil?
    # Content modification actions require current project to be set
    # Including classes set the accreditation requirements.
    current_project.present? &&
      user_is_accredited?(current_project) &&
      record.project == current_project
  end

  def update?
    # Protect against url injection
    return false if user.nil?
    # Content modification actions require current project to be set
    # Including classes set the accreditation requirements.
    current_project.present? &&
      user_is_accredited?(current_project) &&
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

    def user_is_accredited?(project = current_project)
      raise NotImplementedError, "#{self.class.name} must implement user_is_accredited?"
    end
end
