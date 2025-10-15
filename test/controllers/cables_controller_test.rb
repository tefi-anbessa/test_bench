require "test_helper"

class CablesControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do

    @project = create(:project)
    # Set the current project for all tests that need it
    set_current_project(@project) if defined?(set_current_project)

    @admin = create(:user)
    @admin.grant(:admin)

    @project_manager = create(:user)
    @project_manager.grant(:project_manager, @project) # Project manager role

    @team_member = create(:user)
    @team_member.grant(:team_member, @project) # Project team member role

    @electrical_designer = create(:user)
    @electrical_designer.grant(:electrical_designer) # Project electrical designer role
    @electrical_designer.grant(:team_member, @project) # Project team member role

    @regular_user = create(:user)   # No roles

    @discipline = create(:discipline, code: 'E', name: 'Electrical')
    @cable_type = create(:cable_type, project: @project)
    
    # Create tags
    @cable_tag = create(:tag, prefix: 'EC', serial: 1001, project: @project, discipline: @discipline)
    @another_cable_tag = create(:tag, prefix: 'EC', serial: 1002, project: @project, discipline: @discipline)
    
    # Create cable with the cable tag
    @cable = create(:cable, 
                   tag: @cable_tag,
                   cable_type: @cable_type
                   )
    
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  # Index action tests
  test "unauthenticated users should be redirected to sign in" do
    get :index 
    assert_redirected_to new_user_session_url
  end

  test "regular user cannot get index" do
    sign_in @regular_user
    get :index
    assert_response :forbidden
  end

  test "should get index for user with role on current project" do
    sign_in @team_member
    get :index
    assert_response :success
  end

  # Show action tests
  test "user cannot view cable details without a project role" do
    sign_in @regular_user
    get :show, params: { id: @cable.id }
    assert_response :forbidden
  end

  test "team member can view project cable details" do
    sign_in @team_member
    get :show, params: { id: @cable.id }
    assert_response :success
  end

  # New action tests
  test "team member cannot access new cable form" do
    sign_in @team_member
    get :new, params: { tag_id: @another_cable_tag.id }
    assert_response :forbidden
  end

  test "electrical designer can access new cable form for existing unassigned tag" do
    sign_in @electrical_designer
    get :new, params: { tag_id: @another_cable_tag.id }
    assert_response :success
  end

  test "electrical designer can access new cable form with no tag" do
    sign_in @electrical_designer
    get :new
    assert_response :success
  end

  # Create action tests
  # Fail to create
  test "team member cannot create cable" do
    sign_in @team_member
    assert_difference('Cable.count', 0) do
      post :create, params: {
        tag_id: @another_cable_tag.id,
        cable: {
          cable_type_id: @cable_type.id
        }
      }
    end
    assert_forbidden
  end

  test "electrical designer cannot create cable with tag that is not in the database" do
    sign_in @electrical_designer
    @another_cable_tag.update(tagable_type: "Motor")
    assert_difference('Cable.count', 0) do
      post :create, params: {
        tag_id: 99,
        cable: {
          cable_type_id: @cable_type.id
        }
      }
    end
    assert_conflict
  end

  test "electrical designer cannot create cable with tag that already has tagable" do
    sign_in @electrical_designer
    assert_difference('Cable.count', 0) do
      post :create, params: {
        tag_id: @cable_tag.id,
        cable: {
          cable_type_id: @cable_type.id
        }
      }
    end
    assert_conflict
  end

  test "electrical designer cannot create cable with tag that is already classified as other than cable" do
    sign_in @electrical_designer
    @another_cable_tag.update(tagable_type: "Motor")
    assert_difference('Cable.count', 0) do
      post :create, params: {
        tag_id: @another_cable_tag.id,
        cable: {
          cable_type_id: @cable_type.id
        }
      }
    end
    assert_conflict
  end

  test "electrical designer cannot create cable on valid tag when cable is not valid" do
    sign_in @electrical_designer
    assert_no_difference('Cable.count') do
      post :create, params: {
        tag_id: @another_cable_tag.id,
        cable: { cable_type_id: nil }
      }
    end
    assert_response :unprocessable_content
    assert_template :new
    assert flash.now[:alert].present?
  end

  test "electrical designer cannot create cable and tag in one transaction when tag is invalid" do
    sign_in @electrical_designer
    assert_no_difference(['Cable.count', 'Tag.count']) do
      post :create, params: {
        cable: { cable_type_id: @cable_type.id },
        tag: {
          project_id: @project.id,
          discipline_id: @discipline.id,
          prefix: '',                 # invalid: required + format
          serial: 2002,
          suffix: '',
          service: 'Invalid tag case',
          stage: 1
        }
      }
    end
    assert_response :unprocessable_content
    assert_template :new
  end

  # Create action tests
  # Success path
  test "electrical designer can create cable with existing unallocated tag" do
    sign_in @electrical_designer
    assert_difference('Cable.count', 1) do
      post :create, params: {
        tag_id: @another_cable_tag.id,
        cable: {
          cable_type_id: @cable_type.id
        }
      }
    end
    assert_redirected_to Cable.last

    cable = Cable.last
    @another_cable_tag.reload

    # Associations are wired correctly
    assert_equal @another_cable_tag, cable.tag
    assert_equal cable, @another_cable_tag.tagable

    # Flash message confirms success
    expected = I18n.t('flash.tagables.assigned_to', tag: @another_cable_tag.full_tag, resource_name: Cable.model_name.human, id: cable.id)
    assert_equal expected, flash[:success]
  end

  test "electrical designer can create cable and tag in a single request" do
    sign_in @electrical_designer
    initial_tags = Tag.count
    initial_cables = Cable.count
    initial_cable_ids = Cable.pluck(:id)
    
    post :create, params: {
      cable: {
        cable_type_id: @cable_type.id,
        tag: {
          project_id: @project.id,
          discipline_id: @discipline.id,
          prefix: 'EC',
          serial: 2001,
          suffix: '',
          service: 'One-shot cable',
          stage: 1
        }
      }
    }
  
    # Debug out
    # puts "Initial cable IDs: #{initial_cable_ids.inspect}"
    # puts "All cables after create: #{Cable.pluck(:id).inspect}"
    # puts "New cables: #{Cable.where.not(id: initial_cable_ids).pluck(:id).inspect}"
  
    # Check counts
    assert_equal initial_tags + 1, Tag.count, "Tag count should increase by 1"
    assert_equal initial_cables + 1, Cable.count, "Cable count should increase by 1"
    
    assert_redirected_to Cable.last

    cable = Cable.last
    tag = Tag.last

    # Associations are wired correctly
    assert_equal tag, cable.tag
    assert_equal cable, tag.tagable

    # Tag attributes persisted
    assert_equal @project, tag.project
    assert_equal @discipline, tag.discipline
    assert_equal 'EC', tag.prefix
    assert_equal 2001, tag.serial
    assert_equal '', tag.suffix
    assert_equal 'One-shot cable', tag.service

    # Cable attributes persisted
    assert_equal @cable_type, cable.cable_type

    # Flash message confirms success
    assert flash[:success].present?
  end

  # Edit action tests
  test "team member cannot edit cable" do
    sign_in @team_member
    get :edit, params: { id: @cable.id }
    assert_forbidden
  end

  test "electrical designer can edit cable" do
    sign_in @electrical_designer
    get :edit, params: { id: @cable.id }
    assert_response :success
  end

  # Update action tests
  test "electrical designer can update cable" do
    sign_in @electrical_designer
    patch :update, params: { 
      id: @cable.id,
      cable: { 
        cable_type_id: @cable_type.id,
        route_length: 15.0,
        termination_allowance: 0.75
      } 
    }
    assert_redirected_to cable_path(@cable)
    expected = I18n.t('flash.actions.update.notice', resource_name: Cable.model_name.human)
    assert_equal expected, flash[:success]
  end

  test "update shows error when update fails" do
    sign_in @electrical_designer
    # Simulate a validation error by providing invalid data
    patch :update, params: { 
      id: @cable.id,
      cable: { 
        cable_type_id: nil  # This should be invalid
      }
    }
    assert_template :edit
    expected = I18n.t('flash.actions.update.alert', resource_name: Cable.model_name.human.downcase)
    assert_equal expected, flash.now[:alert]
  end

  # Destroy action tests
  test "electrical designer cannot destroy cable" do
    sign_in @electrical_designer
    assert_no_difference('Cable.count') do
      delete :destroy, params: { id: @cable.id }
    end
    assert_forbidden
  end

  test "admin can destroy cable" do
    sign_in @admin
    assert_difference('Cable.count', -1) do
      delete :destroy, params: { id: @cable.id }
    end
    assert_redirected_to cables_path
    expected = I18n.t('flash.actions.destroy.notice', resource_name: Cable.model_name.human)
    assert_equal expected, flash[:notice]
  end
end
