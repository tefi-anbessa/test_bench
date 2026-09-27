# frozen_string_literal: true

# Base policy for resources that are tagable.
# Scope and access are based on current project, user, and the resource's class.
# View actions (show and index) only require users to have a project role on the current project
# The policy uses the resource's discipline to find the required role for content modification actions.
# If required role is not specified for the discipline, the resource's class required role will be used.
# Classes generally inherit the required role from the discipline's base class.
# Delete action is only available to admins.
# The policy delegates checking of the associated tag's project to the tag policy, 
# controllers must authorize both tag and tagable when required.
class TagablePolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      if current_project.present? && 
          (user_has_project_role?(current_project) || 
          user&.is_admin? || 
          user&.is_app_owner?)
        scope.joins(tag: { discipline: :project })
           .where(projects: { id: current_project.id })
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
      # Admin and app_owner can view when current project is nil
      user&.is_admin? || user&.is_app_owner?
    end
  end

  def new?
    # Protect against url injection
    return false if user.nil?
    # Content modification actions require current project to be set
    return false unless current_project.present?
    # Unlike create?, new? is genuinely checked before any discipline is
    # chosen (the bare resource class, not an instance - see the shared
    # TagablePolicyTest's own new? tests, which always pass a nil record) -
    # this generic "has at least one discipline role in the project" check
    # is intentional here, not stale, and record_discipline isn't available
    # to narrow it further at this point.
    user_has_a_required_role?(current_project) ||
      user&.is_admin? ||
      user&.is_app_owner? ||
      user&.is_project_admin_of?(current_project)
  end

  def create?
    # Protect against url injection
    return false if user.nil?
    # Content modification actions require current project to be set
    return false unless current_project.present?
    discipline = record_discipline
    user_is_accredited?(discipline) && discipline&.project == current_project
  end

  def edit?
    # Protect against url injection
    return false if user.nil?
    # Content modification actions require current project to be set
    return false unless current_project.present?
    user_is_accredited?(record.discipline) && record.project == current_project
  end

  def update?
    # Protect against url injection
    return false if user.nil?
    # Content modification actions require current project to be set
    return false unless current_project.present?
    user_is_accredited?(record.discipline) && record.project == current_project
  end

  def destroy?
    # Protect against url injection
    return false if user.nil?
    user&.is_admin? || 
    user&.is_app_owner? || 
    (user&.is_project_admin_of?(current_project) && record.project == current_project)
  end

  private

    # record.discipline (has_one, through: :tag) only resolves via a real
    # SQL join, which requires the tag to already be persisted - for a
    # brand-new tagable being authorized before its tag is saved,
    # record.discipline is nil even when a discipline is genuinely already
    # known. record.tag itself is always already set at this point (built
    # directly by TagablesController#create/#new), and tag.discipline is a
    # plain belongs_to, which resolves correctly in memory regardless of
    # whether the tag has been saved yet - confirmed directly against an
    # unsaved tag+tagable pair.
    def record_discipline
      record.tag&.discipline
    end
end
