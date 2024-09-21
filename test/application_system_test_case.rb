require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :chrome, screen_size: [1400, 1400]
  setup do
    default_url_options[:locale] = I18n.default_locale
  end
end
