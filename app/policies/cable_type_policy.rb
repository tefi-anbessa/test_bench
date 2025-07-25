class CableTypePolicy < ApplicationPolicy

  attr_reader :user, :cable_type

  def initialize(user, cable_type)
    @user = user
    @cable_type = cable_type
  end

  def index?
    can_read?(@user, @cable_type)
  end

  def show?
    can_read?(@user, @cable_type)
  end

  def update?
    can_edit?(@user, @cable_type)
  end

  def create?
    can_create?(@user, @cable_type)
  end

  def destroy?
    can_create?(@user, @cable_type)
  end

  def edit?
    can_edit?(@user, @cable_type)
  end


  class Scope < ApplicationPolicy::Scope
    # Any cable_type for which the user has a role can be listed.
    def resolve
      scope.with_roles([:reader, :author, :editor, :checker, :approver, :admin, :owner], user)
    end
  end
end
