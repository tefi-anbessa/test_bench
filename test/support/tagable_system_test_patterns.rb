module TagableSystemTestPatterns
  extend ActiveSupport::Concern

  def setup_common_tagable_data
    # Each system test must:
    # 1. Create its core discipline (e.g., @respource_discipline = create(:discipline, code: 'E'))
    # 2. Create any other required disciplines (e.g., @discipline_a = create(:discipline, code: 'A'))
    # 3. Create credentialed users with appropriate roles (see below)

    # Create project
    @project = create(:project)

    # Set current project for all tests
    set_current_project(@project) if defined?(set_current_project)
    ApplicationController.any_instance.stubs(:current_project).returns(@project)

    # Create users with roles
    # No credentials for project
    @regular_user = create(:user)

    # Sysadmins
    @app_owner = create(:user)
    @app_owner.grant(:app_owner)

    @admin = create(:user)
    @admin.grant(:admin)

    # Project roles
    @project_manager = create(:user)
    @project_manager.grant(:project_manager, @project)

    @team_member = create(:user)
    @team_member.grant(:team_member, @project)

    # Each system test must create its own credentialed users
    # Example for electrical:
    # @electrical_designer = create(:user)
    # @electrical_designer.grant(:team_member, @project)
    # @electrical_designer.grant(:electrical_designer)
  end

  # Common navigation helpers
  # Each system test must define its own navigate_to_index method
  def navigate_to_index(model_name)
    raise NotImplementedError, "System test must implement navigate_to_index for #{model_name}"
  end

  def navigate_to_show_page(resource_path)
    visit resource_path
  end

  # Common authentication helpers
  def assert_unauthenticated_redirect
    visit root_url
    # Each system test must define what navigation elements should be absent when unauthenticated
    # For example: refute_selector "#electrical-menu-btn" for electrical models
  end

  def assert_role_based_access(user, model_name, actions)
    sign_in user

    actions.each do |action|
      case action
      when :index
        # Each system test must implement its own navigation to index
        # navigate_to_index(model_name)
        # assert_current_path send("#{model_name}s_path")
      when :show
        navigate_to_show_page(send("#{model_name}_path", send("@#{model_name}")))
        assert_current_path send("#{model_name}_path", send("@#{model_name}"))
      when :edit
        visit send("edit_#{model_name}_path", send("@#{model_name}"))
        assert_current_path send("edit_#{model_name}_path", send("@#{model_name}"))
      when :delete
        # Implementation depends on where delete is triggered from
      end
    end
  end

  # Tag fields for show view
  def tag_form_assertions(tag = nil)
    # Field labels
    assert_text I18n.t('activerecord.attributes.tag.project')
    assert_text I18n.t('activerecord.attributes.tag.stage')
    assert_text I18n.t('activerecord.attributes.tag.serial')
    assert_text I18n.t('activerecord.attributes.tag.suffix')
    assert_text I18n.t('activerecord.attributes.tag.service')
    assert_text I18n.t('activerecord.attributes.tag.notes')
    
    if tag.present?
      # Data
      assert_text tag.stage
      assert_text tag.prefix
      assert_text tag.serial
      assert_text tag.suffix
      assert_text tag.service
      assert_text tag.notes
    end
  end

  # Common form interaction helpers
  def fill_tag_fields(prefix, serial, suffix: "", service: nil)
    if has_selector?("select[name*='tag][project_id']")
      select(@project.code, from: "tag][project_id]")
    end
    fill_in "tag][stage]", with: "3"
    fill_in "tag][serial]", with: serial.to_s
    fill_in "tag][suffix]", with: suffix if suffix.present?
    fill_in "tag][service]", with: service || "TEST #{prefix} #{serial}"
    fill_in "tag][notes]", with: "TAG NOTES"
  end

  def submit_form_and_assert_success(model_name, tag_prefix, expected_discipline_code = nil)
    click_button I18n.t('actions.save')
    sleep 0.5  # Give database time to commit

    # Each system test must implement its own tag finding logic
    # since different disciplines may have different tag formats
    new_tag = find_created_tag(tag_prefix)
    assert_current_path send("#{model_name}_path", new_tag.send(model_name))

    # Check tag format if discipline code is provided
    if expected_discipline_code
      assert_text "#{expected_discipline_code}:#{tag_prefix}-5555"
    end
  end

  # Each system test must implement this method to find the created tag
  def find_created_tag(tag_prefix)
    raise NotImplementedError, "System test must implement find_created_tag for #{tag_prefix}"
  end

  # Common assertion helpers
  def assert_common_index_elements(model_name, resource_instance)
    assert_text I18n.t("#{model_name}s.index.header")
    assert page.title.include?(I18n.t("#{model_name}s.index.title"))
    assert_text I18n.t('activerecord.models.tag')

    # Check resource data is displayed
    assert_text resource_instance.tag.label
    assert_text resource_instance.to_s
  end

  def assert_common_show_elements(model_name, resource_instance)
    assert_text I18n.t("#{model_name}s.show.header", label: resource_instance.label)
    assert page.title.include?(I18n.t("#{model_name}s.show.title"))

    # Tag section
    assert_text I18n.t('activerecord.models.tag')
    assert_text resource_instance.tag.full_tag
  end

  def assert_role_navigation_links(model_name, resource_instance, can_edit: false, can_delete: false)
    assert_selector "a[href='#{send("#{model_name}s_path")}']" # Back to index

    if can_edit
      assert_selector "a[href='#{send("edit_#{model_name}_path", resource_instance)}']"
    else
      refute_selector "a[href='#{send("edit_#{model_name}_path", resource_instance)}']"
    end

    if can_delete
      assert_selector "a[href='#{send("#{model_name}_path", resource_instance)}'][data-method='delete']"
    else
      refute_selector "a[href='#{send("#{model_name}_path", resource_instance)}'][data-method='delete']"
    end
  end

  private

end
