# frozen_string_literal: true

# Base policy for resources that belong to a project (Document, CableType, LineType etc.)
# Class must delegate or implement project method.
# Tagable resources should inherit from TagablePolicy.

class ResourcePolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      if current_project.present? && user_has_project_role?(current_project)
        if scope.respond_to?(:discipline)
          scope.joins(discipline: :project)
             .where(projects: { id: current_project.id })
        elsif scope.respond_to?(:project)
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

  def required_role
    model = record.is_a?(Class) ? record : record.class
    unless model.respond_to?(:required_role)
      raise NotImplementedError, "Model #{model} must implement required_role"
    end
    model.required_role
  end

  def index?
    # Protect against url injection
    return false if user.nil?
    if current_project.present?
      user_has_project_role?(current_project)
    else
      # Admin and app_owner can view when current project is nil
      user&.is_admin? || user&.is_app_owner?
    end
  end

  def show?
    # Protect against url injection
    return false if user.nil?
    if current_project.present?
      user_has_project_role?(current_project) && record.project == current_project
    else
      # Admin and app_owner can view when current project is nil
      user&.is_admin? || user&.is_app_owner?
    end
  end

  def new?
    # Protect against url injection
    return false if user.nil?
    user_is_accredited?(current_project)
  end

  def create?
    # Protect against url injection
    return false if user.nil?
    user_is_accredited?(current_project)
  end

  def edit?
    update?
  end

  def update?
    # Protect against url injection
    return false if user.nil?
    user_is_accredited?(current_project) && record.project == current_project
  end

  def destroy?
    # Protect against url injection
    return false if user.nil?
    user&.is_admin? || user&.is_app_owner?
  end

  private

  def user_is_accredited?(project)
    (user_has_project_role?(project) && user.has_role?(required_role)) || user.is_admin? || user.is_app_owner?
  end
end
