# frozen_string_literal: true
require "test_helper"
require "helpers/controller_test_helper"

class DisciplinesControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers
  include ControllerTestHelper

  setup do
    # Don't use the standard helper setup, discipline model will get confused.
    setup_projects_and_users
    setup_disciplines(name: "Electrical", required_role: :designer)
    setup_accredited_users
    setup_model_specific_data
  end

  def setup_model_specific_data
    # Override accredited users. :project_admin can create disciplines
    @accredited_user = @project_admin
    # Give accredited user the required role to pass the setup test.
    @accredited_user.grant(:designer, @discipline)
    # Set up instances of discipline
    @resource = @project.disciplines.find_by(name: "Electrical")
    @other_resource = @other_project.disciplines.find_by(name: "Electrical")
  end

  # Override out of scope test - discipline authorises before scope check
  def test_regular_user_cannot_access_index
    sign_in_and_set_project @regular_user, @project
    get :index, params: index_nesting_params
    assert_forbidden
  end

  test "returns conflict response for invalid required_role injection attempt" do
    sign_in_and_set_project(@project_manager, @project)
    assert_no_difference('Discipline.count') do
      post :create, params: new_nesting_params.merge(create_params).deep_merge({ discipline: { required_role: 'admin' } })
    end
    assert_conflict
  end

  test "project manager can edit their discipline" do
    sign_in_and_set_project(@project_manager, @project)
    get :edit, params: { id: @discipline.id, project_id: @project.id }
    assert_response :success
  end
  
  test "shows error flash when project update fails" do
    sign_in_and_set_project(@project_manager, @project)
    original_name = @discipline.name
    patch :update, params: {
      id: @discipline.id, project_id: @project.id,
      discipline: {
        code: 'a'*6  # Invalid: code max length is 5
      }
    }
    assert_template :edit
    assert_equal original_name, @discipline.reload.name
    assert_equal I18n.t('flash.update.alert', resource_name: I18n.t('activerecord.models.discipline.one')), flash[:alert]
  end

  test "project manager can update discipline on their project" do
    sign_in_and_set_project(@project_manager, @project)
    patch :update, params: {
      id: @discipline.id, project_id: @project.id,
      discipline: {
        name: 'Owner Updated Title'
      }
    }
    assert_redirected_to discipline_url(@discipline)
    assert_equal 'Owner Updated Title', @discipline.reload.name
    assert_equal I18n.t('flash.actions.update.notice', resource_name: I18n.t('activerecord.models.discipline.one')), flash[:success]
  end

  # Destroy action tests
  # Accredited user for disciplines is project_admin, so can destroy.
  undef test_accredited_user_cannot_destroy
  test "project admin can destroy discipline" do
    sign_in_and_set_project(@project_admin, @project)
    assert_difference('Discipline.count', -1) do
      delete :destroy, params: { id: @discipline.id }
    end
    assert_redirected_to project_disciplines_url(@discipline.project)
    assert_equal I18n.t('flash.destroy.notice', resource_name: I18n.t('activerecord.models.discipline.one')), 
                  flash[:success]
  end

  test "admin can destroy discipline" do
    sign_in_and_set_project(@admin, @project)
    assert_difference('Discipline.count', -1) do
      delete :destroy, params: { id: @discipline.id }
    end
    assert_redirected_to project_disciplines_url(@discipline.project)
    assert_equal I18n.t('flash.destroy.notice', resource_name: I18n.t('activerecord.models.discipline.one')), 
                  flash[:success]
  end

  private

    # Required for nested routes
    def new_nesting_params
      { project_id: @project.id }
    end

    # Required for nested routes
    def index_nesting_params
      { project_id: @project.id }
    end

    # Set the expected params for a valid resource create
    def create_params
      { discipline: 
        {
        name: "Test Discipline",
        code: "TD",
        prefix_schema: "name: default",
        required_role: "designer"
        } 
      }
    end

    # No read only attributes
    def update_params
      create_params
    end

    # Set one invalid resource param for tests
    def invalid_param
      { discipline: { code: "xxxxxx" } }
    end

    # Nominate an attribute to get changed during update tests
    def update_attribute_name
      :required_role
    end

    # Nominate a valid value to update the attribute to
    def updated_attribute_value
      "checker"
    end

end
