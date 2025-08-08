class RolePolicy < ApplicationPolicy

    attr_reader :user, :role

    def initialize(user, tag)
      @user = user
      @tag = tag
    end

    def index?
      true
    end

    def show?
      true
    end

    def update?
      role_admin?
    end

    def create?
      @user.is_owner? || @user.is_owner?
    end

    def destroy?
      @user.is_owner? || @user.is_owner?
    end

    def edit?
      @user.is_owner? || @user.is_owner?
    end

    private
      def role_admin
        @user.is_owner? || @user.is_owner?
      end

  class Scope < ApplicationPolicy::Scope
    # NOTE: Be explicit about which records you allow access to!
    def resolve
      scope.all
    end
  end
end
