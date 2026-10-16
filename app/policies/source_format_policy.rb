# frozen_string_literal: true

class SourceFormatPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end

  # Returns the resource record
  def source_format
    record
  end

  def index?
    # Protect against url injection
    return false if user.nil?
    true 
  end

  def show?
    # Protect against url injection
    return false if user.nil?
    true 
  end

  def new?
    # Protect against url injection
    return false if user.nil?
    user.is_admin? || user.is_app_owner? || user.roles.exists?(name: :project_admin) || 
      user.roles.exists?(name: :document_controller)
  end

  def create?
    # Protect against url injection
    return false if user.nil?
    user.is_admin? || user.is_app_owner? || user.roles.exists?(name: :project_admin) || 
      user.roles.exists?(name: :document_controller)
  end

  def edit?
    # Protect against url injection
    return false if user.nil?
    # Matrix: Edit SourceFormat is Global-Admin-only (unlike Create, which
    # also allows project_admin/document_controller - editing shared,
    # system-wide reference data is more tightly held than contributing to it).
    user.is_admin? || user.is_app_owner?
  end

  def update?
    # Protect against url injection
    return false if user.nil?
    user.is_admin? || user.is_app_owner?
  end

  def destroy?
    # Protect against url injection
    return false if user.nil?
    user.is_admin? || user.is_app_owner?
  end
end
