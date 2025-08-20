class CableTypePolicy < ApplicationPolicy
  attr_reader :user, :cable_type, :project

  def initialize(user, cable_type)
    super
    @cable_type = record
    @project = @cable_type.respond_to?(:project) && @cable_type.persisted? ? @cable_type.project : current_project
  end

  class Scope < Scope
    attr_reader :current_project

    def initialize(user, scope, current_project = nil)
      super(user, scope)
      @current_project = current_project
    end

    def resolve
      if current_project.present?
        scope.where(project: current_project)
      else
        scope.none
      end
    end
  end

  def index?
    # Anyone can list cable types if there's a selected project
    project.present?
  end

  def show?
    # Can view if the cable type belongs to the current project
    project.present? && cable_type.project == project
  end

  def new?
    create?
  end

  def create?
    # Can create if user has electrical designer role and a project is selected
    # and is a team member of the project
    project.present? && electrical_designer_with_access?
  end

  def edit?
    update?
  end

  def update?
    # Can update if cable type belongs to current project and user has electrical designer role
    project.present? && 
    cable_type.project == project &&
    electrical_designer_with_access?
  end
  
  private
  
  def electrical_designer_with_access?
    (user.has_role?(:electrical_designer, project) || 
     user.has_role?(:electrical_designer)) &&
    user.has_role?(:team_member, project)
  end

  def current_project
    @current_project ||= begin
      if @cable_type.persisted?
        @cable_type.project
      elsif defined?(controller) && controller.respond_to?(:current_project)
        controller.current_project
      end
    end
  end
end
