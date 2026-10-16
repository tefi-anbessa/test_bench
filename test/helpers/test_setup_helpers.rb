# frozen_string_literal: true
module TestSetupHelpers
  # creates core users with associated roles
  def setup_projects_and_users
    # Create a swatch for the app_theme. Some models default to this swatch and 
    # expect it to be there in views.
    create(:swatch, name: 'app_theme')
    # Create a swatch for the resource's module. Controllers default to this when
    # discipline does not define a swatch.
    @swatch = if defined?(resource_class) && resource_class.module_parent_name.present?
                create(:swatch, name: resource_class.module_parent_name)
              else
                Swatch.find_by(name: 'app_theme')
              end

    # Define two projects for in and out of scope tests
    # Projects are created with standard disciplines
    @project = create(:project)
    @other_project = create(:project)

    # Create users with global roles using traits
    @app_owner = create(:user, :app_owner)
    @admin = create(:user, :admin)

    # Create users with project scoped roles
    @project_manager = create(:user)
    @project_manager.grant(:project_manager, @project)
    @project_admin = create(:user)
    @project_admin.grant(:project_admin, @project)
    @team_member = create(:user)
    @team_member.grant(:team_member, @project)
    @team_member_other_project = create(:user)
    @team_member_other_project.grant(:team_member, @other_project)

    # Create user with no roles
    @regular_user = create(:user)
  end

  # Simple version for model and service tests that don't need users
  def setup_projects
    @project = create(:project)
    @other_project = create(:project)
  end

  def setup_disciplines(name: nil, required_role: :designer)
    # Priority 1: Use explicitly provided name
    # Priority 2: Try to find from resource_class module
    discipline_name = name || (defined?(resource_class) && resource_class.module_parent_name)
    
    @discipline = @project.disciplines.find_by(name: discipline_name)
    @other_discipline = @other_project.disciplines.find_by(name: discipline_name)
    
    # Priority 3: Fail loudly if not found
    raise ArgumentError, "Could not find discipline '#{discipline_name}' in project. " \
                        "Specify a valid name or ensure resource_class is defined." if @discipline.nil?

    @discipline.update(required_role: required_role) if required_role.present?
    @discipline.update(swatch: @swatch)
    @other_discipline.update(required_role: required_role) if required_role.present?
    @other_discipline.update(swatch: @swatch)
  end

  def setup_accredited_users(role = :designer)
    # Set up users with edit permissions on the test disciplines.
    @accredited_user = create(:user)
    @accredited_user.grant(role, @discipline)
    @accredited_user_other_project = create(:user)
    @accredited_user_other_project.grant(role, @other_discipline)
  end


  # Including class must implement resource_class method
  def setup_project_resources
    @resource = create(resource_class.model_name.param_key, project: @project)
    @other_resource = create(resource_class.model_name.param_key, project: @other_project)
    @new_resource = build(resource_class.model_name.param_key, project: @project)
    @new_other_resource = build(resource_class.model_name.param_key, project: @other_project)
  end

  # Including class must implement resource_class method
  def setup_discipline_resources
    @resource = create(resource_class.model_name.param_key, discipline: @discipline)
    @other_resource = create(resource_class.model_name.param_key, discipline: @other_discipline)
    @new_resource = build(resource_class.model_name.param_key, discipline: @discipline)
    @new_other_resource = build(resource_class.model_name.param_key, discipline: @other_discipline)
  end

  def setup_tags
    @tag = create(:tag, :unique_tag, discipline: @discipline, service: "Tag in current project")
    @tag2 = create(:tag, :unique_tag, discipline: @discipline, service: "2nd tag in current project")
    @other_tag = create(:tag, :unique_tag, discipline: @other_discipline, service: "Tag in other project")
    @unassigned_tag = create(:tag, :unique_tag, discipline: @discipline, service: "Unassigned tag")
  end

  # Must run setup_disciplines first
  def setup_documents
    @document = create(:document, discipline: @discipline)
    @other_document = create(:document, discipline: @other_discipline)
  end

  # Must run setup_documents first
  def setup_issues
    @issue = create(:issue, document: @document)
    @other_issue = create(:issue, document: @other_document)
  end

  # Including class must implement resource_class method. The generic form
  # of setup_project_resources/setup_discipline_resources, for a resource
  # nested under some other association (:tag, :document, :issue, etc) that
  # doesn't get its own named helper - builds an in-scope and an
  # out-of-scope resource/new_resource pair for policy tests.
  def setup_nested_discipline_resources(nesting, parent, other_parent)
    @resource = create(resource_class.model_name.param_key, nesting => parent)
    @other_resource = create(resource_class.model_name.param_key, nesting => other_parent)
    @new_resource = build(resource_class.model_name.param_key, nesting => parent)
    @new_other_resource = build(resource_class.model_name.param_key, nesting => other_parent)
  end

  # Including class must implement resource_class method. Builds two
  # resources in the *same* scope (unlike setup_project_resources/
  # setup_discipline_resources, which build an in-scope and an
  # out-of-scope one for policy tests) - used by NestedResourceSystemTests
  # for the next/previous navigation test. `nesting` is the association
  # name to nest under (:project, :discipline, :tag, :document, etc), or
  # :none for no parent at all.
  def setup_nested_resources(nesting, parent)
    attrs = nesting == :none ? {} : { nesting => parent }
    @resource = create(resource_class.model_name.param_key, **attrs)
    @resource2 = create(resource_class.model_name.param_key, **attrs)
  end

  # Including class must implement resource_class method
  # Must run setup_tags first
  def setup_tagable_resources
    @resource = create(resource_class.model_name.param_key, tag: @tag)
    @resource2 = create(resource_class.model_name.param_key, tag: @tag2)
    @other_resource = create(resource_class.model_name.param_key, tag: @other_tag)
  end

  # Helper methods

  # Signs in user and sets current project (order matters: must sign in first)
  def sign_in_and_set_project(user, project)
    sign_in user
    set_current_project(project)
  end
  
  # returns user_context for given user and project
  def user_context(user, project)
    ApplicationPolicy::UserContext.new(user, project)
  end
end
