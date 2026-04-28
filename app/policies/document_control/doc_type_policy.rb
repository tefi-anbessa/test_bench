# frozen_string_literal: true
module DocumentControl
  class DocTypePolicy < ApplicationPolicy

    class Scope < ApplicationPolicy::Scope
      def resolve
        if current_project.present? && 
          (user_has_project_role?(current_project) || user&.is_admin? || user&.is_app_owner?)
            scope.joins(:discipline).where(disciplines: { project_id: current_project.id })
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
      # Protect against url injection
      return false if user.nil?
      # Content modification actions require current project to be set
      return false unless current_project.present?
      # new? action is a special case for discipline scoped resources. 
      # User must have at least one discpline role to access new, or have admin role.
      user_is_accredited?(record) || 
        user&.is_admin? || 
        user&.is_app_owner? ||
        user&.is_project_admin_of?(current_project)
    end

    def create?
      # Protect against url injection
      return false if user.nil?
      # Content modification actions require current project to be set
      return false unless current_project.present?
      user_is_accredited?(record) && record.project == current_project
    end

    def edit?
      # Protect against url injection
      return false if user.nil?
      # Content modification actions require current project to be set
      return false unless current_project.present?
      user_is_accredited?(record) && record.project == current_project
    end

    def update?
      # Protect against url injection
      return false if user.nil?
      # Content modification actions require current project to be set
      return false unless current_project.present?
      user_is_accredited?(record) && record.project == current_project
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
      def user_is_accredited?(record)
        user.has_role?(:document_controller, record.discipline) || 
          user.has_role?(:document_controller, record.discipline.project) || 
          user.is_admin? || 
          user.is_app_owner? ||
          user.is_project_admin_of?(record.project)
      end
  end
end
