require "test_helper"

class SiteTest < ActionDispatch::IntegrationTest

  test "layout links" do
    get root_path
    assert_template 'site/home'
    assert_select "a[href=?]", root_path, count: 1
    assert_select "a[href=?]", site_help_path
    assert_select "a[href=?]", site_about_path
    assert_select "a[href=?]", site_contact_path
  end
end
