require "test_helper"

class TagsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @project = create(:project)
    set_current_project(@project)
    @discipline = create(:discipline, :e)
    @tag = create(:tag, project: @project, discipline: @discipline)

    # Set up users
    @admin = create(:user)
    @regular_user = create(:user)
    @project_manager = create(:user)
    @team_member = create(:user)
    
    # Add global admin role
    @admin.grant(:admin)

    # Add project-specific team member roles
    @project_manager.grant(:project_manager, @project)
    @team_member.grant(:team_member, @project)
  end

  # Authentication tests
  test "unauthenticated users should be redirected to sign in" do
    get :index
    assert_unauthenticated
  end

  # Index tests
  test "users without team role on current project are forbidden to access tag index" do
    sign_in @regular_user
    get :index
    assert_forbidden
  end

  test "team members on current project can view tag index" do
    sign_in @team_member
    get :index
    assert_response :success
    assert_not_nil assigns(:tags)
  end

  # Show tests
  test "users without team role on current project are forbidden to access tag show" do
    sign_in @regular_user
    get :show, params: { id: @tag.id }
    assert_forbidden
  end

  test "team members on current project can view tag show" do
    sign_in @team_member
    get :show, params: { id: @tag.id }
    assert_response :success
  end

  # New action tests
  test "users without team role on current project are forbidden to access new tag form" do
    sign_in @regular_user
    get :new
    assert_forbidden
  end

  test "team members on current project can access new tag form" do
    sign_in @team_member
    get :new
    assert_response :success
  end

  # Create action tests
  test "users without team role on current project are forbidden to create tags" do
    sign_in @regular_user
    assert_no_difference("Tag.count") do
      post :create, params: { tag: { service: @tag.service,
                                      discipline_id: @tag.discipline_id,
                                      serial: @tag.serial + 1,
                                      notes: @tag.notes,
                                      prefix: @tag.prefix,
                                      project_id: @tag.project_id,
                                      stage: @tag.stage,
                                      suffix: @tag.suffix } }
    end
    assert_forbidden
  end

  test "team members on current project can create tag" do
    sign_in @team_member
    assert_difference("Tag.count", 1) do
      post :create, params: { tag: { service: @tag.service,
                                      discipline_id: @tag.discipline_id,
                                      serial: @tag.serial + 1,
                                      notes: @tag.notes,
                                      prefix: @tag.prefix,
                                      project_id: @tag.project_id,
                                      stage: @tag.stage,
                                      suffix: @tag.suffix } }
    end
    assert_redirected_to tag_url(Tag.last)
  end

  # Edit action tests
  test "users without team role on current project are forbidden to access edit tag form" do
    sign_in @regular_user
    get :edit, params: { id: @tag.id }
    assert_forbidden
  end

  test "team members on current project can access edit tag form" do
    sign_in @team_member
    get :edit, params: { id: @tag.id }
    assert_response :success
  end

  # Update action tests
  test "users without team role on current project are forbidden to update tag" do
    sign_in @regular_user
    original_service = @tag.service
    patch :update, params: { id: @tag.id,
                              tag: { service: @tag.service + " modified",
                              discipline_id: @tag.discipline_id,
                              serial: @tag.serial,
                              notes: @tag.notes,
                              prefix: @tag.prefix,
                              project_id: @tag.project_id,
                              stage: @tag.stage,
                              suffix: @tag.suffix } }
    assert_equal @tag.service, original_service
    assert_forbidden
  end

  test "team members on current project can update tag" do
    sign_in @team_member
    original_service = @tag.service
    patch :update, params: { id: @tag.id,
                              tag: { service: @tag.service + "modified",
                              discipline_id: @tag.discipline_id,
                              serial: @tag.serial,
                              notes: @tag.notes,
                              prefix: @tag.prefix,
                              project_id: @tag.project_id,
                              stage: @tag.stage,
                              suffix: @tag.suffix } }
    assert_equal @tag.service, original_service
    assert_redirected_to tag_url(@tag)
  end

  # Destroy action tests
  test "users other than admin are forbidden to destroy tag" do
    sign_in @project_manager
    assert_no_difference("Tag.count") do
      delete :destroy, params: { id: @tag.id }
    end
    assert_forbidden
  end

  test "should destroy tag" do
    sign_in @admin
    assert_difference("Tag.count", -1) do
      delete :destroy, params: { id: @tag.id }
    end
    assert_redirected_to tags_url
  end
end
