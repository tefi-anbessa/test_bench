# frozen_string_literal: true

# Base policy for resources that belong to a discipline (Tag, Document, etc.)
# Class must delegate or implement project method.
# Tagable resources should inherit from TagablePolicy.

class DisciplineResourcePolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      if current_project.present? && 
        (user_has_project_role?(current_project) || user&.is_admin? || user&.is_app_owner?)
        if scope.reflect_on_association(:discipline)
          scope.joins(:discipline).where(disciplines: { project_id: current_project.id })
        elsif scope.reflect_on_association(:project)
          scope.where(project: current_project)
        else
          scope.none
        end
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
        record.discipline.project == current_project
    else
      # Global admins can view any record when current project is nil
      user&.is_admin? || user&.is_app_owner?
    end
  end

  def new?
    # Discipline nested resources must call new? with an instance object belonging to discipline,
    # not a class.
    # Protect against url injection
    return false if user.nil?
    # Ensure record is an instance, not a class
    unless record.is_a?(ApplicationRecord)
      Rails.logger.warn "Policy Error: #{record.class}.new? called with class instead of instance. " \
                       "Use an instance variable with discipline association."
      return false
    end
    # Content modification actions require current project to be set
    return false unless current_project.present?
    # new? action is a special case for discipline scoped resources. 
    # User must have at least one discpline role to access new, or have admin role.
    user_is_accredited?(current_project)
  end

  def create?
    # Protect against url injection
    return false if user.nil?
    # Ensure record is an instance, not a class
    unless record.is_a?(ApplicationRecord)
      Rails.logger.warn "Policy Error: #{record.class}.new? called with class instead of instance. " \
                       "Use an instance variable with discipline association."
      return false
    end
    # Content modification actions require current project to be set
    return false unless current_project.present?
    user_is_accredited?(current_project) && record.project == current_project
  end

  def edit?
    # Protect against url injection
    return false if user.nil?
    # Content modification actions require current project to be set
    return false unless current_project.present?
    user_is_accredited?(current_project) && record.project == current_project
  end

  def update?
    # Protect against url injection
    return false if user.nil?
    # Content modification actions require current project to be set
    return false unless current_project.present?
    user_is_accredited?(current_project) && record.project == current_project
  end

  def destroy?
    # Protect against url injection
    return false if user.nil?
    user&.is_admin? || 
    user&.is_app_owner? || 
    (user&.is_project_admin_of?(current_project) && record.project == current_project)
  end

  private

    # This method returns true when the user has permission for content modification actions.
    def user_is_accredited?(project)
      rr = record.discipline.required_role.present? ? 
          record.discipline.required_role.to_s : 
          "#{record.discipline.name}::Base".safe_constantize&.required_role.to_s
      user.has_role?(rr, record.discipline) || 
        user.is_admin? || 
        user.is_app_owner? ||
        user.is_project_admin_of?(project)
    end
end
