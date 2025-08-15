class CableTypePolicy < ApplicationPolicy

  attr_reader :user, :cable_type

  def initialize(user, cable_type)
    @user = user
    @cable_type = cable_type
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
    user.has_any_role? :owner, :admin, { name: :creator, resource: CableType }
  end

  def edit?
    user.has_any_role? :owner, :admin, { name: :creator, resource: CableType },
                                        {name: :editor, resource: CableType },
                                        {name: :checker, resource: CableType },
                                        {name: :approver, resource: CableType }
  end

  def update?
    edit?
  end

  def destroy?
    create?
  end


  class Scope < ApplicationPolicy::Scope
    # Any cable_type can be listed.
    def resolve
      CableType.all
    end
  end
end
