require "test_helper"

class RolesControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    # Project context
    @project = create(:project)
    set_current_project(@project)
    
    # Users
    @role = create(:role)
    @regular_user = create(:user)
    @electrical_designer = create(:user)
    @project_owner = create(:user)
    @admin = create(:user, :admin)
    @app_owner = create(:user, :app_owner)
    
    # Roles
    @electrical_designer.grant(:team_member, @project)
    @electrical_designer.grant(:electrical_designer)
    @project_owner.grant(:project_owner, @project)
  end

  # Authentication tests
  test "unauthenticated user cannot access any action" do
    get :index
    assert_unauthenticated
  end

  # Index tests
  test "regular user cannot view roles index" do
    sign_in @regular_user
    get :index
    assert_forbidden
  end

  test "admin can view roles index" do
    sign_in @admin
    get :index
    assert_response :success
  end

  # New tests
  test "regular user cannot access new role form" do
    sign_in @regular_user
    get :new
    assert_forbidden
  end

  test "admin can access new role form" do
    sign_in @admin
    get :new
    assert_response :success
  end

  # Create tests
  test "regular user cannot create global role" do
    sign_in @regular_user
    post :create, params: { role: { user_id: @regular_user.id,
                                    name: :electrical_designer,
                                    resource_type: "",
                                    resource_id: ""} }
    refute @regular_user.has_role?(:electrical_designer)
    assert_forbidden
  end

  test "admin can create global role" do
    sign_in @admin
    post :create, params: { role: { user_id: @regular_user.id,
                                    name: :electrical_designer,
                                    resource_type: "",
                                    resource_id: ""} }
    assert @regular_user.has_role?(:electrical_designer)
    assert_equal flash_message('global', :grant), flash[:success]
    assert_redirected_to roles_url
  end

  test "regular user cannot create resource-wide role" do
    sign_in @regular_user
    post :create, params: { role: { user_id: @regular_user.id,
                                    name: :team_member,
                                    resource_type: @project.class,
                                    resource_id: ""} }
    refute @regular_user.has_role?(:team_member, @project.class)
    assert_forbidden
  end

  test "admin can create resource-wide role" do
    sign_in @admin
    post :create, params: { role: { user_id: @regular_user.id,
                                    name: :team_member,
                                    resource_type: @project.class,
                                    resource_id: ""} }
    assert @regular_user.has_role?(:team_member, @project.class)
    assert_equal flash_message('resource_wide', :grant), flash[:success]
    assert_redirected_to roles_url
  end

  test "regular user cannot create resource instance role" do
    sign_in @regular_user
    post :create, params: { role: { user_id: @regular_user.id,
                                    name: :team_member,
                                    resource_type: @project.class.to_s,
                                    resource_id: @project.id} }
    refute @regular_user.has_role?(:team_member, @project)
    assert_forbidden
  end

  test "admin can create resource instance role" do
    sign_in @admin
    post :create, params: { role: { user_id: @regular_user.id,
                                    name: :team_member,
                                    resource_type: @project.class.to_s,
                                    resource_id: @project.id} }
    assert @regular_user.has_role?(:team_member, @project)
    assert_equal flash_message('resource_instance', :grant), flash[:success]
    assert_redirected_to edit_project_path(@project.id)
  end

# Test failure cases for create action
test "fails to create role with invalid user" do
  sign_in @admin
  assert_no_difference 'Role.count' do
    post :create, params: { 
      role: { 
        user_id: 999999,  # Non-existent user
        name: :team_member,
        resource_type: @project.class.to_s,
        resource_id: @project.id
      } 
    }
  end
  assert_match I18n.t('flash.roles.user_not_found'), flash[:danger]
  assert_response :not_found
end

test "fails to create role with invalid resource" do
  sign_in @admin
  assert_no_changes -> { @regular_user.has_role?(:team_member, nil) } do
    post :create, params: { 
      role: { 
        user_id: @regular_user.id,
        name: :team_member,
        resource_type: 'NonExistentResource',
        resource_id: 999
      } 
    }
  end
  assert_match I18n.t('flash.roles.resource_not_found'), flash[:danger]
  assert_response :not_found
end

  # Destroy tests
  test "regular user cannot revoke global role" do
    sign_in @regular_user
    delete :destroy, params: { user_id: @electrical_designer.id, 
                id: @electrical_designer.roles.where(name: 'electrical_designer', resource: nil).first.id }
    assert @electrical_designer.has_role?(:electrical_designer)
    assert_forbidden
  end

  test "admin can revoke global role" do
    sign_in @admin
    delete :destroy, params: { user_id: @electrical_designer.id, 
                id: @electrical_designer.roles.where(name: 'electrical_designer', resource: nil).first.id }
    refute @electrical_designer.has_role?(:electrical_designer)
    assert_equal flash_message('global', :revoke), flash[:success]
    assert_redirected_to roles_url
  end

  test "regular user cannot revoke resource-wide role" do
    sign_in @electrical_designer
    # Create the role we want to destroy: resource wide roles are not used in the app at this time
    @electrical_designer.grant(:team_member, Project)
    role = @electrical_designer.roles.find_by(name: 'team_member', resource_type: 'Project', resource_id: nil)
    delete :destroy, params: { 
      user_id: @electrical_designer.id, 
      id: role.id 
    }
    assert @electrical_designer.has_role?(:team_member, Project)
    assert_forbidden
  end

  test "admin can revoke resource-wide role" do
    sign_in @admin
    # Create the role we want to destroy: resource wide roles are not used in the app at this time
    @electrical_designer.grant(:team_member, Project)
    role = @electrical_designer.roles.find_by(name: 'team_member', resource_type: 'Project', resource_id: nil)
    delete :destroy, params: { user_id: @electrical_designer.id, 
                  id: role.id }
    refute @electrical_designer.has_role?(:team_member, Project)
    assert_equal flash_message('resource_wide', :revoke), flash[:success]
    assert_redirected_to roles_url
  end

  test "regular user cannot revoke resource instance role" do
    sign_in @electrical_designer
    delete :destroy, params: { user_id: @electrical_designer.id, 
                                id: @electrical_designer.roles.where(name: 'team_member', resource: @project).first.id }
    assert @electrical_designer.has_role?(:team_member, @project)
    assert_forbidden
  end

  test "project owner can revoke resource instance role" do
    sign_in @project_owner
    @electrical_designer.grant(:team_member, @project)
    delete :destroy, params: { user_id: @electrical_designer.id, 
                          id: @electrical_designer.roles.where(name: 'team_member', resource: @project).first.id }
    refute @electrical_designer.has_role?(:team_member, @project)
    assert_equal flash_message('resource_instance', :revoke), flash[:success]
    assert_redirected_to edit_project_path(@project.id)
  end

  # Test failure cases for destroy action
test "fails to revoke non-existent role" do
  sign_in @admin
  non_existent_role_id = 999999
  delete :destroy, params: { 
    id: non_existent_role_id,
    user_id: @regular_user.id
  }
  assert_match I18n.t('flash.roles.role_not_found'), flash[:danger]
  assert_response :not_found
end

test "admin cannot grant admin role" do
  sign_in @admin
  assert_no_changes -> { @regular_user.has_role?(:admin) } do
    post :create, params: { 
      role: { 
        user_id: @regular_user.id,
        name: 'admin',
        resource_type: '',
        resource_id: ''
      } 
    }
  end
  assert_equal I18n.t('flash.roles.insufficient_permissions'), flash[:danger]
  assert_response :forbidden
end

test "app_owner can grant admin role" do
  sign_in @app_owner
  assert_changes -> { @regular_user.has_role?(:admin) }, from: false, to: true do
    post :create, params: { 
      role: { 
        user_id: @regular_user.id,
        name: 'admin',
        resource_type: '',
        resource_id: ''
      } 
    }
  end
  assert_redirected_to roles_url
end

test "admin cannot revoke admin role" do
  # First create an admin role as app_owner
  admin_role = nil
  sign_in @app_owner
  assert_changes -> { @regular_user.has_role?(:admin) }, from: false, to: true do
    post :create, params: { 
      role: { 
        user_id: @regular_user.id,
        name: 'admin',
        resource_type: '',
        resource_id: ''
      } 
    }
    admin_role = @regular_user.roles.find_by(name: 'admin')
  end
  sign_out @app_owner
  
  # Now try to revoke as admin
  sign_in @admin
  assert_no_changes -> { @regular_user.has_role?(:admin) } do
    delete :destroy, params: { id: admin_role.id, user_id: @regular_user.id }
  end
  assert_equal I18n.t('flash.roles.insufficient_permissions'), flash[:danger]
  assert_response :forbidden
end

test "app_owner can revoke admin role" do
  # First create an admin role as app_owner
  admin_role = nil
  sign_in @app_owner
  assert_changes -> { @regular_user.has_role?(:admin) }, from: false, to: true do
    post :create, params: { 
      role: { 
        user_id: @regular_user.id,
        name: 'admin',
        resource_type: '',
        resource_id: ''
      } 
    }
    admin_role = @regular_user.roles.find_by(name: 'admin')
  end
  
  # Now revoke as app_owner
  assert_changes -> { @regular_user.has_role?(:admin) }, from: true, to: false do
    delete :destroy, params: { id: admin_role.id, user_id: @regular_user.id }
  end
  assert_redirected_to roles_url
end

private
    def flash_message(role_type, action_type)
      case action_type
      when :grant
         I18n.t('flash.roles.granted', role_type: I18n.t("flash.role_types.#{role_type}"))
      when :revoke
         I18n.t('flash.roles.revoked', role_type: I18n.t("flash.role_types.#{role_type}"))
      end
    end
end
