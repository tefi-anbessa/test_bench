require "application_system_test_case"

class TagsSystemTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers
  include Warden::Test::Helpers

  setup do
    @user = create(:user)
    @project = create(:project)
    @discipline = create(:discipline, code: 'E', name: 'Electrical Engineering')
    login_as(@user, scope: :user)
  end

  test "visiting the tags index" do
    tags = create_list(:tag, 3, project: @project, discipline: @discipline)
    visit tags_path
    
    assert_selector "h2", text: I18n.t('tags.index.header')
    tags.each do |tag|
      assert_text tag.full_tag
    end
  end

  test "creating a new tag" do
    visit new_tag_path
    
    # Fill in the form with valid data
    select @project.name, from: 'tag_project_id'
    select @discipline.name, from: 'tag_discipline_id'
    select 'CC', from: 'tag_prefix'
    fill_in 'tag_serial', with: '123'
    fill_in 'tag_service', with: 'Test Service'
    
    assert_difference('Tag.count') do
      click_on I18n.t('helpers.submit.create')
    end
    
    assert_text I18n.t('notices.created', model: Tag.model_name.human)
    assert_text "CC-123"
  end

  test "viewing a tag" do
    tag = create(:tag, prefix: 'CC', serial: 123, project: @project, discipline: @discipline)
    visit tag_path(tag)
    
    assert_text "CC-123"
    assert_text tag.service
  end

  test "updating a tag" do
    tag = create(:tag, prefix: 'CC', serial: 123, project: @project, discipline: @discipline)
    visit edit_tag_path(tag)
    
    fill_in 'tag_serial', with: '456'
    click_on I18n.t('helpers.submit.update')
    
    assert_text I18n.t('notices.updated', model: Tag.model_name.human)
    assert_text "CC-456"
  end

  test "deleting a tag" do
    tag = create(:tag, prefix: 'CC', serial: 123, project: @project, discipline: @discipline)
    visit tags_path
    
    accept_confirm do
      click_on I18n.t('actions.delete'), match: :first
    end
    
    assert_text I18n.t('notices.destroyed', model: Tag.model_name.human)
    assert_no_text "CC-123"
  end

  test "searching tags by prefix" do
    create(:tag, prefix: 'CC', serial: 123, project: @project, discipline: @discipline)
    create(:tag, prefix: 'FT', serial: 456, project: @project, discipline: @discipline)
    
    visit tags_path
    fill_in 'q[prefix_cont]', with: 'CC'
    click_on I18n.t('helpers.submit.search')
    
    assert_text "CC-123"
    assert_no_text "FT-456"
  end

  test "searching tags by serial" do
    create(:tag, prefix: 'CC', serial: 123, project: @project, discipline: @discipline)
    create(:tag, prefix: 'FT', serial: 456, project: @project, discipline: @discipline)
    
    visit tags_path
    fill_in 'q[serial_cont]', with: '123'
    click_on I18n.t('helpers.submit.search')
    
    assert_text "CC-123"
    assert_no_text "FT-456"
  end

  test "searching tags by service" do
    create(:tag, prefix: 'CC', serial: 123, service: 'Pump 1', project: @project, discipline: @discipline)
    create(:tag, prefix: 'FT', serial: 456, service: 'Valve 1', project: @project, discipline: @discipline)
    
    visit tags_path
    fill_in 'q[service_cont]', with: 'Pump'
    click_on I18n.t('helpers.submit.search')
    
    assert_text "CC-123"
    assert_text "Pump 1"
    assert_no_text "Valve 1"
  end

  test "navigating between tags" do
    tag1 = create(:tag, prefix: 'CC', serial: 1, project: @project, discipline: @discipline)
    tag2 = create(:tag, prefix: 'CC', serial: 2, project: @project, discipline: @discipline)
    
    visit tag_path(tag1)
    click_on I18n.t('actions.next')
    
    assert_current_path tag_path(tag2)
    
    click_on I18n.t('actions.previous')
    assert_current_path tag_path(tag1)
  end
end
