# frozen_string_literal: true
module ProjectChange
  class RequestPolicy < ProjectResourcePolicy

    # Define accreditation for project change requests
    # Any team member can create/edit requests (per matrix)
    def user_is_accredited?(project = current_project)
      return false if user.nil?
      # Ensure record is an instance, not a class.
      # The rails error is only for development transition phase.
      unless record.is_a?(ApplicationRecord)
        unless Rails.env.production?
          raise "Policy Error: #{record.class} called with class instead of instance. " \
                "Use an instance variable with discipline association."
        end
        return false
      end
      user_has_project_role?(record.project) ||
        user.is_admin? ||
        user.is_app_owner?
    end
    
    # Inherit Scope from ProjectResourcePolicy
    
    # Inherit all actions from ProjectResourcePolicy
  end
end
