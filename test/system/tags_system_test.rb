require "application_system_test_case"

class TagsSystemTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers
  include Warden::Test::Helpers

  setup do
    @user = create(:user)
    @project = create(:project)
    @discipline_b = create(:discipline, code: 'B')
    @discipline_e = create(:discipline, code: 'E')
    @discipline_j = create(:discipline, code: 'J')
    @discipline_p = create(:discipline, code: 'P')

    @app_owner = create(:user)
    @app_owner.grant(:app_owner)

    @admin = create(:user)
    @admin.grant(:admin)

    @project_manager = create(:user)
    @project_manager.grant(:project_manager, @project)

    @team_member = create(:user)
    @team_member.grant(:team_member, @project)

    @regular_user = create(:user)

    @tag = create(:tag, project: @project, stage: '1', discipline: @discipline_e, 
      prefix: 'EC', serial: '1', suffix: "i", service: 'TEST TAG E:EC-0001.i', notes: "Lorem ipsum",
      tagable_type: "Cable")
    @tag.reload
    # Set the current project for all tests that need it
    set_current_project(@project) if defined?(set_current_project)
  end

  test "unauthenticated users should not see tags link" do
    visit root_url
    refute_selector "a[href='tags_url']"
  end

  test "team member viewing the tags index" do
    sign_in @team_member
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit root_url
    
    # Click the tag index link
    click_link(href: tags_path)
    assert_current_path tags_path
    assert_text I18n.t("tags.index.header")
    assert page.title.include?(I18n.t("tags.index.title"))

    # team member can create new tag
    assert_selector "a[href='#{new_tag_path}']" 

    # index search fields and headers
    assert_selector "input[name='q[prefix_cont]']"
    assert_selector "input[name='q[serial_cont]']"
    assert_selector "input[name='q[service_cont]']"
    assert_selector "input[name='q[notes_cont]']"
    assert_selector "a[href*='q%5Bs%5D=stage']"
    assert_selector "a[href*='q%5Bs%5D=service']"

    # index fields
    assert_text @tag.stage
    assert_text @tag.label
    assert_text @tag.service
    assert_text @tag.prefix
    assert_text @tag.serial
    assert_text @tag.stage

    # Links
    assert_selector "a[href='#{tag_path(@tag)}']"
    assert_selector "a[href='#{edit_tag_path(@tag)}']" # team member can edit tag
    refute_selector "a[href='#{tag_path(@tag)}'][data-method='delete']" # team member cannot delete tag
  end

  test "admin viewing the tags index" do
    sign_in @admin
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit root_url
    
    # Click the dropdown toggle
    click_link(href: tags_path)
    assert_current_path tags_path

    assert_selector "a[href='#{tag_path(@tag)}'][data-method='delete']" # admin can delete tag
  end

  test "team member viewing the tag show view" do
    sign_in @team_member
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit tags_path
    click_link(href: tag_path(@tag))
    assert_current_path tag_path(@tag)
    assert_text I18n.t("tags.show.header", label: @tag.label)
    assert page.title.include?(I18n.t("tags.show.title"))

    # Header bar navigation links
    assert_selector "a[href='#{tags_path}']"# Link back to tags index
    assert_selector "a[href='#{edit_tag_path(@tag)}']" # team member can edit tag
    refute_selector "a[href='#{tag_path(@tag)}'][data-method='delete']" # team member cannot delete tag
    # [TODO] test prev and next buttons

    # Project collapsible card
    assert_text I18n.t('activerecord.models.project')
    assert_text @tag.project.code

    # Field labels
    assert_text I18n.t('activerecord.attributes.tag.stage')
    assert_text I18n.t('activerecord.models.discipline')
    assert_text I18n.t('activerecord.attributes.tag.full_tag')
    assert_text I18n.t('activerecord.attributes.tag.prefix')
    assert_text I18n.t('activerecord.attributes.tag.serial')
    assert_text I18n.t('activerecord.attributes.tag.suffix')
    assert_text I18n.t('activerecord.attributes.tag.service')
    assert_text I18n.t('activerecord.attributes.tag.notes')
    assert_text I18n.t('activerecord.attributes.tag.tagable_type')
    assert_text @tag.stage
    assert_text @tag.discipline.code
    assert_text @tag.label
    assert_text @tag.prefix
    assert_text @tag.serial
    assert_text @tag.suffix
    assert_text @tag.service
    assert_text @tag.notes
    assert_text @tag.tagable_type.constantize.model_name.human
  end

  test "admin viewing the tag show view" do
    sign_in @admin
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit tags_path
    find("a[href='#{tag_path(@tag)}'][title=#{I18n.t('actions.show')}").click
    assert_current_path tag_path(@tag)
    assert_selector "a[href='#{tag_path(@tag)}'][data-method='delete']" # admin can delete tag
  end

  test "team member viewing the tag new view" do
    sign_in @team_member
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit tags_path
    click_link(href: new_tag_path)
    assert_current_path new_tag_path
    assert_text I18n.t("tags.new.header")
    assert page.title.include?(I18n.t("tags.new.title"))

    # Data fields
    assert_selector "input[name='tag[stage]']"
    assert_selector "select[name='tag[discipline_id]']"
    assert_selector "input[name='tag[serial]']"
    assert_selector "input[name='tag[suffix]']"
    assert_selector "input[name='tag[service]']"
    assert_selector "textarea[name='tag[notes]']"
    assert_selector "select[name='tag[tagable_type]']"

    # Form buttons
    assert_selector "input[type='submit']"
    assert_selector "a.btn.btn-warning", text: I18n.t('actions.discard')
  end

  test "selecting discipline sets the prefix schema" do
    sign_in @team_member
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit tags_path
    click_link(href: new_tag_path)
    assert_current_path new_tag_path

    select("J", from: "tag[discipline_id]", match: :first)
    assert_selector "select[name='measured_variable']"
    assert_selector "select[name='modifier']"
    assert_selector "select[name='function']"
    assert_selector "select[name='modifier_function']"
    assert_selector "[data-tag-target='prefixField'][readonly]"

    select("P", from: "tag[discipline_id]", match: :first)
    refute_selector "select[name='measured_variable']"
    refute_selector "select[name='modifier']"
    refute_selector "select[name='function']"
    refute_selector "select[name='modifier_function']"
    refute_selector "[data-tag-target='prefixField'][readonly]"
    assert_selector "input[name='tag[prefix]']"
    
    select("B", from: "tag[discipline_id]", match: :first)
    refute_selector "select[name='measured_variable']"
    refute_selector "select[name='modifier']"
    refute_selector "select[name='function']"
    refute_selector "select[name='modifier_function']"
    refute_selector "[data-tag-target='prefixField'][readonly]"
    assert_selector "select[name='tag[prefix]']"
  end

  test "team member create new tag" do
    sign_in @team_member
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit new_tag_path
    assert_current_path new_tag_path

    # Build instrument tag J:AT-0101.A
    fill_in "tag_stage", with: "1"
    select("J", from: "tag[discipline_id]", match: :first)
    select("A", from: "measured_variable", match: :first)
    select("T", from: "function", match: :first)
    fill_in "tag_serial", with: "0101"
    fill_in "tag_suffix", with: "A"
    fill_in "tag_service", with: "MAIN STREAM ANALYSIS"

    click_button I18n.t('actions.save')
    sleep 0.1  # Give database time to commit
    new_tag = Tag.find_by(prefix: "AT", serial: "0101", suffix: "A")
    assert_current_path tag_path(new_tag)
    assert_text "J:AT-0101.A"
    assert_text I18n.t("flash.actions.create.notice", resource_name: I18n.t("activerecord.models.tag"))
  end

  test "team member edit tag" do
    sign_in @team_member
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit tag_path(@tag)
    click_link(href: edit_tag_path(@tag))
    assert_current_path edit_tag_path(@tag)
    assert_text I18n.t("tags.edit.header", label: @tag.reload.label)
    assert page.title.include?(I18n.t("tags.edit.title"))

    # Data fields
    assert_selector "input[name='tag[stage]']"
    assert_selector "select[name='tag[discipline_id]']"
    assert_selector "input[name='tag[serial]']"
    assert_selector "input[name='tag[suffix]']"
    assert_selector "input[name='tag[service]']"
    assert_selector "textarea[name='tag[notes]']"
    assert_selector "select[name='tag[tagable_type]']"

    # Prefix fields should be present as discipline is already set to "E"
    assert_selector "select[name='measured_variable']"
    assert_selector "select[name='modifier']"
    assert_selector "select[name='function']"
    assert_selector "select[name='modifier_function']"
    assert_selector "[data-tag-target='prefixField'][readonly]"

    # Complete the form
    fill_in "tag_serial", with: "0101"
    fill_in "tag_suffix", with: "A"
    fill_in "tag_service", with: "MODIFIED SERVICE"
    click_button I18n.t('actions.save')

    assert_current_path tag_path(@tag)
    assert_text "E:EC-0101.A"
    assert_text "MODIFIED SERVICE"
    assert_text I18n.t("flash.actions.update.notice", resource_name: I18n.t("activerecord.models.tag"))

    # Make another edit to test the show view link, and then discard
    click_link(href: edit_tag_path(@tag))
    assert_current_path edit_tag_path(@tag)
    fill_in "tag_serial", with: "0201"
    
    fill_in "tag_service", with: "RESTORED SERVICE"
    accept_confirm do
      click_link(text: I18n.t('actions.discard'))
    end
    assert_current_path tag_path(@tag)
    assert_text "E:EC-0101.A"
    refute_text "RESTORED SERVICE"
  end

  test "admin destroy tag from the index view" do
    sign_in @admin
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit tags_path
     # Find the actual delete link and inspect its href
    accept_confirm do
      find("a[href='#{tag_path(@tag)}'][data-method='delete']").click
    end
    assert_current_path tags_path
    refute_selector "a[href='#{tag_path(@tag)}']"
    assert_text I18n.t("flash.actions.destroy.notice", resource_name: I18n.t("activerecord.models.tag"))
  end

  test "admin destroy tag from the show view" do
    sign_in @admin
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit tag_path(@tag)
     # Find the actual delete link and inspect its href
    accept_confirm do
      find("a[href='#{tag_path(@tag)}'][data-method='delete']").click
    end
    assert_current_path tags_path
    refute_selector "a[href='#{tag_path(@tag)}']"
    assert_text I18n.t("flash.actions.destroy.notice", resource_name: I18n.t("activerecord.models.tag"))
  end
end
