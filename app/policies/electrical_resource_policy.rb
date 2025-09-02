# frozen_string_literal: true

# Base policy for electrical resources that are taggable (Cable, Switchboard, Motor, etc.)
# This policy should only be used for models that are taggable (have a tag association)
# Inherits common behavior from TagPolicy and adds electrical designer role requirements
class ElectricalResourcePolicy < TagPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless current_project
      scope.joins(:tag).where(tags: { project: current_project })
    end
  end

  # Override this in subclasses if different role is needed
  def self.required_role
    :electrical_designer
  end

  def index?
    return true if user&.is_admin? || user&.is_app_owner?
    current_project.present? && user_has_project_role?
  end

  def show?
    return true if user&.is_admin? || user&.is_app_owner?
    return false unless user && current_project && record
    user_has_project_role? && record.tag.project == current_project
  end

  def new?
    create?
  end

  def create?
    return false if user.nil? || current_project.nil?
    return true if user&.is_admin? || user&.is_app_owner?
    user_has_project_role? && user_has_required_role?
  end

  def edit?
    update?
  end

  def update?
    return false if user.nil? || current_project.nil?
    return true if user&.is_admin? || user&.is_app_owner?
    user_has_project_role? && user_has_required_role?
  end

  def destroy?
    user&.is_admin? || user&.is_app_owner?
  end

  private

  def user_has_required_role?
    user_has_project_role? && user.has_role?(self.class.required_role)
  end
end
