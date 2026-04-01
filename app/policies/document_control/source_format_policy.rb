# frozen_string_literal: true
module DocumentControl
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
      true
    end

    def show?
      true
    end

    def new?
      create?
    end

    def create?
      user.is_admin? || user.is_app_owner? || user.has_role?(:document_controller)
    end

    def edit?
      update?
    end

    def update?
      user.is_admin? || user.is_app_owner? || user.has_role?(:document_controller)
    end

    def destroy?
      user.is_admin? || user.is_app_owner?
    end
  end
end
