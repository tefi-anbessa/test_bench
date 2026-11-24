require "test_helper"

class ApplicationControllerTest < ActionDispatch::IntegrationTest
  # Exercises ApplicationController#switch_locale (see
  # app/controllers/application_controller.rb) via a real, unauthenticated
  # action, since it's an around_action on every request - site_home is the
  # simplest available vehicle for that (see SiteControllerTest).

  test "an explicit locale param sets I18n.locale and persists it to a cookie" do
    get site_home_url(locale: "en-AU")
    assert_response :success
    assert_equal "en-AU", cookies[:locale]
  end

  test "renders successfully in every supported locale, including the en-AU region fallback" do
    I18n.available_locales.each do |locale|
      get site_home_url(locale: locale)
      assert_response :success, "expected site_home to render successfully in locale #{locale.inspect}"
    end
  end

  test "without a locale param, a previously-set cookie is honoured" do
    get site_home_url(locale: "km")
    assert_equal "km", cookies[:locale]

    get site_home_url
    assert_response :success
    assert_equal "km", cookies[:locale]
  end
end
