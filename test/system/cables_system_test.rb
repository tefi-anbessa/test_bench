require "application_system_test_case"

class CablesSystemTest < ApplicationSystemTestCase
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

    @electrical_designer = create(:user)
    @electrical_designer.grant(:team_member, @project)
    @electrical_designer.grant(:electrical_designer)

    @regular_user = create(:user)

    @cable_type1 = create(:cable_type, project: @project)
    @cable_type2 = create(:cable_type, csa: 4.0, project: @project)

    @cable_tag = create(:tag, project: @project, stage: '1', discipline: @discipline_e, 
      prefix: 'EC', serial: '1', suffix: "i", service: 'TEST CABLE E:EC-0001.i', notes: "Lorem ipsum",
      tagable_type: "Cable")
    @cable_tag.reload
    @cable = create(:cable, tag: @cable_tag, route_length: 55.5, vertical_allowance: 5.5,
                      termination_allowance: 1.5, start_mark: "154", end_mark: "42", 
                      notes: "test cable for electrical designer")
    # Set the current project for all tests that need it
    set_current_project(@project) if defined?(set_current_project)
    @cable_tag2 = create(:tag, project: @project, stage: '1', discipline: @discipline_e, 
      prefix: 'EC', serial: '2', suffix: "k", service: 'TEST CABLE E:EC-0002.k', notes: "Persisted tag",
      tagable_type: "Cable")
    @cable_tag2.reload
  end

  test "unauthenticated users should not see electrical drop down" do
    visit root_url
    refute_selector "#electrical-menu-btn"
  end

  test "team member viewing the cable index" do
    sign_in @team_member
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit root_url
    
    # Click the tag index link
    find("#electrical-menu-btn").click
    
    within "[aria-labelledby='electrical-menu-btn']" do
      assert_selector "a", text: I18n.t('cable', scope: 'activerecord.models').pluralize
      click_on I18n.t('cable', scope: 'activerecord.models').pluralize
    end
    assert_current_path cables_path
    assert_text I18n.t("cables.index.header")
    assert page.title.include?(I18n.t("cables.index.title"))

    assert_text I18n.t('activerecord.models.tag')
    assert_selector "a[href*='q%5Bs%5D=tag_stage']"
    assert_selector "a[href*='q%5Bs%5D=cable_type_id']"
    assert_selector "a[href*='q%5Bs%5D=route_length']"

    assert_text @cable.tag.label
    assert_text @cable.tag.stage
    assert_text @cable.cable_type_id
    assert_text @cable.route_length

    # Links
    assert_selector "a[href='#{cable_path(@cable)}']"
    refute_selector "a[href='#{edit_cable_path(@cable)}']" # team member cannot edit cable
    refute_selector "a[href='#{cable_path(@cable)}'][data-method='delete']" # team member cannot delete cable
  end

  test "electrical designer viewing the cable index" do
    sign_in @electrical_designer
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit cables_path
    assert_current_path cables_path

    assert_selector "a[href='#{edit_cable_path(@cable)}']" # electrical designer can edit cable
    refute_selector "a[href='#{cable_path(@cable)}'][data-method='delete']" # electrical designer cannot delete cable
  end

  test "admin viewing the cable index" do
    sign_in @admin
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit cables_path
    assert_current_path cables_path

    assert_selector "a[href='#{cable_path(@cable)}'][data-method='delete']" # admin can delete cable
  end

  test "team member viewing the cable show view" do
    sign_in @team_member
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit cables_path
    click_link(href: cable_path(@cable))
    assert_current_path cable_path(@cable)
    assert_text I18n.t("cables.show.header", label: @cable.label)
    assert page.title.include?(I18n.t("cables.show.title"))

    # Header bar navigation links
    assert_selector "a[href='#{cables_path}']"# Link back to cables index
    refute_selector "a[href='#{edit_cable_path(@cable)}']" # team member cannot edit cable
    refute_selector "a[href='#{cable_path(@cable)}'][data-method='delete']" # team member cannot delete cable
    # [TODO] test prev and next buttons

    # Tag collapsible card
    assert_text I18n.t('activerecord.models.tag')
    assert_text @cable.tag.full_tag

    # Cable type collapsible card
    assert_text I18n.t('activerecord.models.cable_type')
    assert_text @cable.cable_type_id

    # Field labels
    assert_text I18n.t('activerecord.attributes.cable.from')
    assert_text I18n.t('activerecord.attributes.cable.to')
    assert_text I18n.t('activerecord.attributes.cable.route_length')
    assert_text I18n.t('activerecord.attributes.cable.vertical_allowance')
    assert_text I18n.t('activerecord.attributes.cable.termination_allowance')
    assert_text I18n.t('activerecord.attributes.cable.start_mark')
    assert_text I18n.t('activerecord.attributes.cable.end_mark')
    assert_text I18n.t('activerecord.attributes.cable.notes')
    
    assert_text @cable.cable_type_id
    assert_text @cable.route_length
    assert_text @cable.vertical_allowance
    assert_text @cable.termination_allowance
    assert_text @cable.start_mark
    assert_text @cable.end_mark
    assert_text @cable.notes
  end

  test "electrical designer view the cable show view" do
    sign_in @electrical_designer
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit cables_path
    click_link(href: cable_path(@cable))
    assert_current_path cable_path(@cable)

    # Header bar navigation links
    assert_selector "a[href='#{edit_cable_path(@cable)}']" # electrical designer can edit cable
    refute_selector "a[href='#{cable_path(@cable)}'][data-method='delete']" # electrical designer cannot delete cable
  end

  test "admin view the cable show view" do
    sign_in @admin
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit cables_path
    find("a[href='#{cable_path(@cable)}'][title=#{I18n.t('actions.show')}").click
    assert_current_path cable_path(@cable)

    # Header bar navigation links
    assert_selector "a[href='#{edit_cable_path(@cable)}']" # admin can edit cable
    assert_selector "a[href='#{cable_path(@cable)}'][data-method='delete']" # admin can delete cable
  end

  test "electrical designer view the new tag and new cable view" do
    sign_in @electrical_designer
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit cables_path
    click_link(href: new_cable_path)
    assert_current_path new_cable_path
    assert_text I18n.t("cables.new.header")
    assert page.title.include?(I18n.t("cables.new.title"))

    # Data fields, tag section
    assert_selector "input[name='cable[tag][stage]']"
    assert_selector "select[name='cable[tag][discipline_id]']"
    assert_selector "input[name='cable[tag][serial]']"
    assert_selector "input[name='cable[tag][suffix]']"
    assert_selector "input[name='cable[tag][service]']"
    assert_selector "textarea[name='cable[tag][notes]']"
    assert_selector "select[name='cable[tag][tagable_type]']"

    # Date fields, cable section
    assert_selector "select[name='cable[cable_type_id]']"
    assert_selector "select[name='cable[from_type]']"
    assert_selector "select[name='cable[from_id]']"
    assert_selector "select[name='cable[to_type]']"
    assert_selector "select[name='cable[to_id]']"
    assert_selector "input[name='cable[route_length]']"
    assert_selector "input[name='cable[vertical_allowance]']"
    assert_selector "input[name='cable[termination_allowance]']"
    assert_selector "input[name='cable[start_mark]']"
    assert_selector "input[name='cable[end_mark]']"
    assert_selector "textarea[name='cable[notes]']"

    # Form buttons
    assert_selector "button[type='submit']"
    assert_selector "a.btn.btn-warning", text: I18n.t('actions.discard')
  end

  test "electrical designer create new tag and new cable" do
    sign_in @electrical_designer
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit cables_path
    click_link(href: new_cable_path)
    assert_current_path new_cable_path

    if has_selector?("select[name='cable[tag][project_id]']")
      select(@project.code, from: "cable[tag][project_id]")
    end
    fill_in "cable[tag][stage]", with: "3"
    fill_in "cable[tag][serial]", with: "5555"
    fill_in "cable[tag][suffix]", with: "HIGH"
    fill_in "cable[tag][service]", with: "TEST CABLE 5555"
    fill_in "cable[tag][notes]", with: "TAG NOTES NONSENSE"
    select("1", from: "cable[cable_type_id]", match: :first)
    fill_in "cable[route_length]", with: "111"
    fill_in "cable[vertical_allowance]", with: "7"
    fill_in "cable[termination_allowance]", with: "4"
    fill_in "cable[start_mark]", with: "360"
    fill_in "cable[end_mark]", with: "471"
    fill_in "cable[notes]", with: "CABLE NOTES 5555"

    # Submit the form data
    click_button I18n.t('actions.save')
    sleep 0.5  # Give database time to commit
    new_tag = Tag.find_by(prefix: "EC", serial: "5555", suffix: "HIGH")
    assert_current_path cable_path(new_tag.cable)
    assert_text "E:EC-5555.HIGH"
    assert_text I18n.t('flash.tagables.created_and_assigned',
                            resource_name: Cable.model_name.human,
                            id: new_tag.cable.id,
                            tag: new_tag.label)
  end

  test "electrical designer create new cable on existing tag" do
    sign_in @electrical_designer
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit tag_path(@cable_tag2)
    click_link(href: new_tag_cable_path(@cable_tag2))
    assert_current_path new_tag_cable_path(@cable_tag2)
    assert_text I18n.t("cables.new.header")
    assert page.title.include?(I18n.t("cables.new.title"))

    # Tag collapsible card header
    assert_text @cable_tag2.label

    # Cable data fields
    select("1", from: "cable[cable_type_id]", match: :first)
    fill_in "cable[route_length]", with: "111"
    fill_in "cable[vertical_allowance]", with: "7"
    fill_in "cable[termination_allowance]", with: "4"
    fill_in "cable[start_mark]", with: "360"
    fill_in "cable[end_mark]", with: "471"
    fill_in "cable[notes]", with: "CABLE NOTES 1002"

    # Submit the form data
    click_button I18n.t('actions.save')
    sleep 0.5  # Give database time to commit
    @cable_tag2.reload
    assert_current_path cable_path(@cable_tag2.cable)
    assert_text "E:EC-0002.k"
    assert_text I18n.t('flash.tagables.assigned_to',
                        resource_name: Cable.model_name.human,
                        id: @cable_tag2.cable.id,
                        tag: @cable_tag2.label)
  end

  test "electrical designer edit cable" do
    sign_in @electrical_designer
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit cable_path(@cable)
    click_link(href: edit_cable_path(@cable))
    assert_current_path edit_cable_path(@cable)
    assert_text I18n.t("cables.edit.header", label: @cable.reload.label)
    assert page.title.include?(I18n.t("cables.edit.title"))

    # Tag collapsible card header
    assert_text @cable.tag.label
    
    # Date fields, cable section
    assert_selector "select[name='cable[cable_type_id]']"
    assert_selector "select[name='cable[from_type]']"
    assert_selector "select[name='cable[from_id]']"
    assert_selector "select[name='cable[to_type]']"
    assert_selector "select[name='cable[to_id]']"
    assert_selector "input[name='cable[route_length]']"
    assert_selector "input[name='cable[vertical_allowance]']"
    assert_selector "input[name='cable[termination_allowance]']"
    assert_selector "input[name='cable[start_mark]']"
    assert_selector "input[name='cable[end_mark]']"
    assert_selector "textarea[name='cable[notes]']"

    # Edit the data
    find("select[name='cable[cable_type_id]'] option[value='2']").select_option
    fill_in "cable[notes]", with: "REVISED FOR TEST"

File.write('debug_page.html', page.html)
    # Submit the form data
    click_button I18n.t('actions.save')
    sleep 0.5  # Give database time to commit
    @cable.reload
    assert_current_path cable_path(@cable)
    assert_text "E:EC-0001.i"
    assert_text "REVISED FOR TEST"
    assert_equal @cable.cable_type_id, 2
    assert_text I18n.t("flash.actions.update.notice", resource_name: Cable.model_name.human)

    # Make another edit to test the show view link, and then discard
    click_link(href: edit_cable_path(@cable))
    assert_current_path edit_cable_path(@cable)
    find("select[name='cable[cable_type_id]'] option[value='1']").select_option
    fill_in "cable[notes]", with: "REINSTATED FOR TEST"
    
    accept_confirm do
      click_link(text: I18n.t('actions.discard'))
    end
    assert_current_path cable_path(@cable)
    refute_equal @cable.cable_type_id, 1
    refute_text "REINSTATED FOR TEST"
  end

  test "admin destroy cable from the index view" do
    sign_in @admin
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit cables_path
     # Find the actual delete link and inspect its href
    accept_confirm do
      find("a[href='#{cable_path(@cable)}'][data-method='delete']").click
    end
    assert_current_path cables_path
    refute_selector "a[href='#{cable_path(@cable)}']"
    assert_text I18n.t("flash.actions.destroy.notice", resource_name: I18n.t("activerecord.models.cable"))
  end

  test "admin destroy cable from the show view" do
    sign_in @admin
    # Mock current_project for this test
    ApplicationController.any_instance.stubs(:current_project).returns(@project)
    visit cable_path(@cable)
     # Find the actual delete link and inspect its href
    accept_confirm do
      find("a[href='#{cable_path(@cable)}'][data-method='delete']").click
    end
    assert_current_path cables_path
    refute_selector "a[href='#{cable_path(@cable)}']"
    assert_text I18n.t("flash.actions.destroy.notice", resource_name: I18n.t("activerecord.models.cable"))
  end
end