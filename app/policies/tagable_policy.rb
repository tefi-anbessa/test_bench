# frozen_string_literal: true

# Base policy for resources that are tagable.
# Scope and access are based on current project, user, and the resource's class.
# View actions (show and index) only require users to have a project role on the current project
# The policy uses the resource's class to find the required role for content modification actions.
# Resources will generally inherit the required role from the discipline's base class.
# Delete action is only available to admins.
# The policy delegates checking of the associated tag's project to the tag policy, 
# controllers must authorize both tag and tagable when required. 
class TagablePolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      if current_project.present? && user_has_project_role?(current_project)
        scope.joins(tag: { discipline: :project })
           .where(projects: { id: current_project.id })
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
      # [TODO: change this to a custom server error.]
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
      user_has_project_role?(current_project) && record.tag.discipline.project == current_project
    else
      # Admin and app_owner can view when current project is nil
      user&.is_admin? || user&.is_app_owner?
    end
  end

  def new?
    create?
  end

  def create?
    # Protect against url injection
    return false if user.nil?
    if current_project.present?
      # pundit has no way to get the project context for the tagable resource being created.
      # authorization relies on the resource controller also checking tag permissions
      # when creating a new tag at the same time as a resource, and using single transaction.
      user_is_accredited?(current_project) 
    else
      # Admin and app_owner can create when current project is nil
      user&.is_admin? || user&.is_app_owner?
    end
  end

  def edit?
    update?
  end

  def update?
    # Protect against url injection
    return false if user.nil?
    if current_project.present?
      # pundit could check the resource's tag to find the project, but the controllers allow
      # for resources to create a new tag through edit, as a way to rescue orphaned resources.
      # As for create, authorization relies on the resource controller also checking tag permissions
      # when creating a new tag at the same time as a resource, and using single transaction.
      user_is_accredited?(current_project) 
    else
      # Admin and app_owner can create when current project is nil
      user&.is_admin? || user&.is_app_owner?
    end
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
