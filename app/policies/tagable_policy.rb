# frozen_string_literal: true

# Base policy for resources that are tagable.
# Scope and access are based on current project, user, and the resource's class.
# View actions (show and index) only require users to have a project role on the current project.
#
# Deliberately does NOT define new?/create?/update?/edit?/destroy? - TagablesController's own
# create/new/edit/update/destroy actions all authorize @tag, never the tagable itself (confirmed
# directly), so TagPolicy (via @tag, e.g. @discipline.tags.build or @tagable.tag) is already the
# real, enforced authorization for all of those - a tagable-specific version here would just be a
# second, easily-drifting check of the same thing. Every real tagable policy (MotorPolicy,
# CablePolicy, ...) is an empty subclass of this one for exactly that reason - there's nothing
# tagable-specific left to override for these actions. index?/show? are different: they're
# checked directly against the tagable/its class (TagablesController#index/#show), so they stay
# here.
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

end
