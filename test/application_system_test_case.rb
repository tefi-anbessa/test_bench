require "test_helper"
require "capybara/selenium/driver_specializations/chrome_driver"

# Chrome 158+ rejects the wildcard origin: '*' that Capybara 3.40.0's
# ChromeDriver#reset! sends to the Storage.clearDataForOrigin CDP command
# on every system test teardown (Selenium::WebDriver::Error::
# InvalidArgumentError: invalid argument: * is not a valid URL) - no
# capybara release fixes this yet. Rescuing just that one known failure
# avoids a false "error" on every system test.
module Capybara::Selenium::Driver::ChromeDriver
  alias_method :reset_without_chrome_wildcard_origin_fix!, :reset!

  def reset!
    reset_without_chrome_wildcard_origin_fix!
  rescue Selenium::WebDriver::Error::InvalidArgumentError => e
    raise unless e.message.include?("is not a valid URL")
  end
end

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :chrome, screen_size: [1400, 2800]
  setup do
    default_url_options[:locale] = I18n.default_locale
  end
end
