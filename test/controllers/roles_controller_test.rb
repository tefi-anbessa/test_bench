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
    @project_manager = create(:user)
    @admin = create(:user, :admin)
    @app_owner = create(:user, :app_owner)
    
    # Roles
    @electrical_designer.grant(:team_member, @project)
    @electrical_designer.grant(:electrical_designer)
    @project_manager.grant(:project_manager, @project)
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
    sign_out @regular_user
  end

  test "admin can view roles index" do
    sign_in @admin
    get :index
    assert_response :success
    sign_out @admin
  end

# Create tests
# Test failing paths in the controller first
  test "admin cannot create invalid resource role" do
    sign_in @admin
    error_message = "Security event: Attempt to create role on invalid resource: NonExistentResource"
    assert_logs(error_message, :error) do
      assert_no_difference '@regular_user.roles.count' do
        post :create, params: { role: { user_id: @regular_user.id,
                                      name: :electrical_designer,
                                      resource_type: 'NonExistentResource',
                                      resource_id: 1,
                                      role_return_path: nil } }
      end
    end
    assert_forbidden
    sign_out @admin
  end

  test "admin cannot create role for non-existent resource instance" do
    sign_in @admin
    non_existent_id = Project.maximum(:id).to_i + 1
    error_message = "Security event: Attempt to create role on non existent resource instance: Project id #{non_existent_id}"
    assert_logs(error_message, :error) do
      assert_no_difference '@regular_user.roles.count' do
        post :create, params: { 
          role: { 
            user_id: @regular_user.id,
            name: :team_member,
            resource_type: 'Project',
            resource_id: non_existent_id,
            role_return_path: nil 
          } 
        }
      end
    end
    assert_forbidden
    sign_out @admin
  end

  test "admin cannot create role with blank user_id" do
    sign_in @admin
    assert_no_difference '@project.roles.count' do
      post :create, params: { 
        role: { 
          user_id: "",  # Blank user_id, easily done on the form
          name: :team_member,
          resource_type: @project.class.to_s,
          resource_id: @project.id,
          role_return_path: edit_project_path(@project)
        } 
      }
    end
    assert_equal I18n.t('rolify.flash.user_id_blank'), flash[:warning]
    assert_response :unprocessable_content
    sign_out @admin
  end

  test "admin cannot create role with invalid user" do
    sign_in @admin
    error_message = "Security event: Attempt to create role for non existent user id: 999999"
    assert_logs(error_message, :error) do
      assert_no_difference '@regular_user.roles.count' do
        post :create, params: { 
          role: { 
            user_id: 999999,  # Non-existent user
            name: :team_member,
            resource_type: @project.class.to_s,
            resource_id: @project.id,
            role_return_path: edit_project_path(@project)
          } 
        }
      end
    end
    assert_forbidden
    sign_out @admin
  end

  test "admin cannot create role with blank role name" do
    sign_in @admin
    assert_no_difference '@regular_user.roles.count' do
      post :create, params: { 
        role: { 
          user_id: @regular_user.id,
          name: "",
          resource_type: @project.class.to_s,
          resource_id: @project.id,
          role_return_path: edit_project_path(@project)
        } 
      }
    end
    assert_equal I18n.t("rolify.flash.name_blank"), flash[:warning]
    assert_response :unprocessable_content
    sign_out @admin
  end

  test "admin cannot create role with invalid role name for the resource" do
    sign_in @admin
    assert_no_difference '@regular_user.roles.count' do
      post :create, params: { 
        role: { 
          user_id: @regular_user.id,  # Valid user
          name: "electrical_designer",
          resource_type: @project.class.to_s,
          resource_id: @project.id,
          role_return_path: edit_project_path(@project)
        } 
      }
    end
    assert_equal I18n.t("rolify.flash.name_invalid", 
      name: I18n.t("rolify.names.electrical_designer"), 
      resource: I18n.t("activerecord.models.#{@project.class.model_name.i18n_key}")), flash[:warning]
    assert_response :unprocessable_content
    sign_out @admin
  end

  test "admin cannot create admin role" do
    sign_in @admin
    error_message = "Security event: Attempt to grant admin role by non app owner: #{@admin.name}"
    assert_logs(error_message, :error) do
      assert_no_difference '@regular_user.roles.count' do
        post :create, params: { 
          role: { 
            user_id: @regular_user.id,  # Valid user
            name: "admin",
            resource_type: nil,
            role_return_path: roles_path
          } 
        }
      end
    end
    assert_forbidden
    sign_out @admin
  end

  # Create tests
  # Success tests
  test "app_owner can create admin role" do
    sign_in @app_owner
    assert_difference '@regular_user.roles.count', 1 do
        post :create, params: { 
          role: { 
            user_id: @regular_user.id,  # Valid user
            name: "admin",
            resource_type: nil,
            role_return_path: roles_path
          } 
        }
      end
    assert_redirected_to roles_url
    assert_equal I18n.t('rolify.flash.granted', role_type: I18n.t('rolify.role_types.global')), flash[:success]
    sign_out @app_owner
  end

  test "admin can create global role" do
    sign_in @admin
    post :create, params: { role: { user_id: @regular_user.id,
                                    name: "electrical_designer",
                                    resource_type: "",
                                    resource_id: "",
                                    role_return_path: roles_path} }
    assert @regular_user.has_role?(:electrical_designer)
    assert_equal flash_message('global', :grant), flash[:success]
    assert_redirected_to roles_url
    sign_out @admin
  end

  test "admin can create resource wide role" do
    sign_in @admin
    post :create, params: { role: { user_id: @regular_user.id,
                                    name: "team_member",
                                    resource_type: "Project",
                                    resource_id: "",
                                    role_return_path: roles_path} }
    # For resource-wide roles, check with the class as the resource
    assert @regular_user.has_role?(:team_member, Project)
    assert_equal flash_message('resource_wide', :grant), flash[:success]
    assert_redirected_to roles_url
    sign_out @admin
  end

  test "admin can create resource instance role" do
    sign_in @admin
    post :create, params: { role: { user_id: @regular_user.id,
                                    name: :team_member,
                                    resource_type: @project.class.to_s,
                                    resource_id: @project.id,
                                    role_return_path: edit_project_path(@project)} }
    assert @regular_user.has_role?(:team_member, @project)
    assert_equal flash_message('resource_instance', :grant), flash[:success]
    assert_redirected_to edit_project_path(@project.id)
    sign_out @admin
  end

  test "project manager can create resource instance role" do
    sign_in @project_manager
    post :create, params: { role: { user_id: @regular_user.id,
                                    name: :team_member,
                                    resource_type: @project.class.to_s,
                                    resource_id: @project.id,
                                    role_return_path: edit_project_path(@project)} }
    assert @regular_user.has_role?(:team_member, @project)
    assert_equal flash_message('resource_instance', :grant), flash[:success]
    assert_redirected_to edit_project_path(@project.id)
    sign_out @project_manager
  end

  # Destroy tests
  # Test failing paths first
  test "admin cannot revoke role that doesn't exist" do
    sign_in @admin
    assert_no_difference '@electrical_designer.roles.count' do
      delete :destroy, params: { user_id: @electrical_designer.id, 
                  id: 9999,
                  role_return_path: roles_path }
    end
    assert_forbidden
    sign_out @admin
  end

  test "admin cannot revoke admin role" do
    # This is actually now a policy test, but it is kept here in case we need it again
    # First create an admin role as app_owner
    admin_role = nil
    sign_in @app_owner
    assert_changes -> { @regular_user.has_role?(:admin) }, from: false, to: true do
      post :create, params: { 
        role: { 
          user_id: @regular_user.id,
          name: 'admin',
          resource_type: '',
          resource_id: '',
          role_return_path: roles_path
        } 
      }
      admin_role = @regular_user.roles.find_by(name: 'admin')
    end
    sign_out @app_owner
    
    # Now try to revoke as admin
    sign_in @admin
    assert_no_changes -> { @regular_user.has_role?(:admin) } do
      delete :destroy, params: { id: admin_role.id, user_id: @regular_user.id, role_return_path: roles_path }
    end
    assert_equal I18n.t('pundit.unauthorized'), flash[:danger]
    assert_response :forbidden
  end

  test "regular user cannot revoke global role" do
    sign_in @regular_user
    delete :destroy, params: { user_id: @electrical_designer.id, 
                id: @electrical_designer.roles.where(name: 'electrical_designer', resource: nil).first.id,
                role_return_path: roles_path }
    assert @electrical_designer.has_role?(:electrical_designer)
    assert_forbidden
  end

  test "regular user cannot revoke resource-wide role" do
    sign_in @electrical_designer
    # Create the role we want to destroy: resource wide roles are not used in the app at this time
    @electrical_designer.grant(:team_member, Project)
    role = @electrical_designer.roles.find_by(name: 'team_member', resource_type: 'Project', resource_id: nil)
    delete :destroy, params: { 
      user_id: @electrical_designer.id, 
      id: role.id,
      role_return_path: roles_path 
    }
    assert @electrical_designer.has_role?(:team_member, Project)
    assert_forbidden
  end

  test "regular user cannot revoke resource instance role" do
    sign_in @electrical_designer
    delete :destroy, params: { user_id: @electrical_designer.id, 
                                id: @electrical_designer.roles.where(name: 'team_member', resource: @project).first.id,
                                role_return_path: edit_project_path(@project) }
    assert @electrical_designer.has_role?(:team_member, @project)
    assert_forbidden
  end

  # Destroy tests
  # Test success paths 

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
          resource_id: '',
          role_return_path: roles_path
        } 
      }
      admin_role = @regular_user.roles.find_by(name: 'admin')
    end
    
    # Now revoke as app_owner
    assert_changes -> { @regular_user.has_role?(:admin) }, from: true, to: false do
      delete :destroy, params: { id: admin_role.id, user_id: @regular_user.id, role_return_path: roles_path }
    end
    assert_redirected_to roles_url
  end

  # Worryingly, app_owner can revoke their own app_owner role
  test "app_owner can revoke app_owner role" do
    sign_in @app_owner
    delete :destroy, params: { user_id: @app_owner.id, 
                id: @app_owner.roles.where(name: 'app_owner', resource: nil).first.id,
                role_return_path: roles_path }
    refute @app_owner.has_role?(:app_owner)
    assert_equal flash_message('global', :revoke), flash[:success]
    assert_redirected_to roles_url
  end

  test "admin can revoke global role" do
    sign_in @admin
    delete :destroy, params: { user_id: @electrical_designer.id, 
                id: @electrical_designer.roles.where(name: 'electrical_designer', resource: nil).first.id,
                role_return_path: roles_path }
    refute @electrical_designer.has_role?(:electrical_designer)
    assert_equal flash_message('global', :revoke), flash[:success]
    assert_redirected_to roles_url
  end

  test "admin can revoke resource-wide role" do
    sign_in @admin
    # Create the role we want to destroy: resource wide roles are not used in the app at this time
    @electrical_designer.grant(:team_member, Project)
    role = @electrical_designer.roles.find_by(name: 'team_member', resource_type: 'Project', resource_id: nil)
    delete :destroy, params: { user_id: @electrical_designer.id, 
                  id: role.id,
                  role_return_path: roles_path }
    refute @electrical_designer.has_role?(:team_member, Project)
    assert_equal flash_message('resource_wide', :revoke), flash[:success]
    assert_redirected_to roles_url
  end

  test "project manager can revoke resource instance role" do
    sign_in @project_manager
    @electrical_designer.grant(:team_member, @project)
    delete :destroy, params: { user_id: @electrical_designer.id, 
                          id: @electrical_designer.roles.where(name: 'team_member', resource: @project).first.id,
                          role_return_path: edit_project_path(@project) }
    refute @electrical_designer.has_role?(:team_member, @project)
    assert_equal flash_message('resource_instance', :revoke), flash[:success]
    assert_redirected_to edit_project_path(@project.id)
  end

  private
    def flash_message(role_type, action_type)
      case action_type
      when :grant
         I18n.t('rolify.flash.granted', role_type: I18n.t("rolify.role_types.#{role_type}"))
      when :revoke
         I18n.t('rolify.flash.revoked', role_type: I18n.t("rolify.role_types.#{role_type}"))
      end
    end
end
