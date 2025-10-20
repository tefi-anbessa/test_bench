require "test_helper"
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require 'devise'
require 'minitest/reporters'
Minitest::Reporters.use!

require 'factory_bot_rails'
require 'database_cleaner/active_record'

# Load test support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

# Configure minitest-reporters
Minitest::Reporters.use!(
  Minitest::Reporters::DefaultReporter.new,
  ENV,
  Minitest.backtrace_filter
)

# Configure DatabaseCleaner
DatabaseCleaner.strategy = :transaction
DatabaseCleaner.clean_with(:truncation)

# mocha gem for stubbing
require 'mocha/minitest'

class ActiveSupport::TestCase
  include Devise::Test::IntegrationHelpers
  # Disable fixtures completely
  # fixtures :all

  # Set up database cleaner
  setup do
    DatabaseCleaner.start
    Rails.application.routes.default_url_options[:locale] = I18n.default_locale
    assign_roles if respond_to?(:assign_roles)
  end

  teardown do
    DatabaseCleaner.clean
  end

  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)

  # Helper method to wait until a condition is met
  def wait_until(timeout = Capybara.default_max_wait_time)
    Timeout.timeout(timeout) do
      sleep(0.1) until value = yield
      value
    end
  rescue Timeout::Error
    raise "Timed out after #{timeout} seconds"
  end

  # Add more helper methods to be used by all tests here...
  include FactoryBot::Syntax::Methods
  
  # Assert that a specific message is logged at the given level
  def assert_logs(message, level = :info, &block)
    original_logger = Rails.logger
    logged = false
    mock_logger = Class.new do
      define_method(level) do |msg|
        logged ||= (msg == message)
      end
      def method_missing(*); end
    end.new
    
    Rails.logger = mock_logger
    yield
    assert logged, "Expected to log: #{message}"
  ensure
    Rails.logger = original_logger
  end
  
  # include Devise::Test::IntegrationHelpers
  
  # Returns the current user
  def current_user
    @current_user
  end
  
  # Returns the current project
  def current_project
    @current_project
  end
  
  # Sets the current project in the session and cookies to match application behavior
  # @param project [Project] The project to set as current
  def set_current_project(project)
    # post set_projects_url, params: { project_id: project.id }
    @current_project = project
    # Also set in session and cookies if controller test
    if defined?(controller) && controller.respond_to?(:session)
      session[:project_id] = project.id
      cookies[:project_id] = project.id
    end
  end
  
  

  # Asserts that the request was rejected because the user is not signed in
  # Verifies:
  # - 302 Found status code
  # - Redirects to sign-in page
  # - Correct flash message
  #
  # @param message [String] Optional custom assertion message
  def assert_unauthenticated(message = nil)
    assert_response :found, message # 302
    assert_redirected_to new_user_session_path, message
    assert_equal I18n.t('devise.failure.unauthenticated'), flash[:alert], message
  end
  
  # Asserts that the request was rejected due to insufficient permissions
  # Verifies:
  # - 302 Found status code
  # - Redirects to root path
  # - Unauthorized flash message
  # (This will be updated to use a custom unauthorized page in the future)
  #
  # @param message [String] Optional custom assertion message

  # This is legacy AI code, it confused itself and wrote assert_forbidden which supersedes this.
  def assert_unauthorized(message = nil)
    assert_response :found, message # 302
    assert_redirected_to root_path, message
    assert_equal I18n.t('pundit.not_authorized'), flash[:alert], message
  end
  
  # Asserts that the request was explicitly forbidden (403)
  # Verifies:
  # - 403 Forbidden status code
  # - Renders the forbidden error page
  # - Optionally checks for a specific message in the response
  #
  # @param message [String] Optional message to check in response body
  def assert_forbidden(message = nil)
    assert_response :forbidden
    if @response.media_type == 'text/html' || @response.media_type == 'text/html; charset=utf-8'
      assert_select 'h1', /403: Forbidden/
      assert_match(/Access Denied/, @response.body)
      assert_match(/#{Regexp.escape(message)}/, @response.body) if message
    end
  end

  # Asserts that the request resulted in a conflict (409)
  # Verifies:
  # - 409 Conflict status code
  # - Renders the conflict error page
  # - Optionally checks for a specific message in the response
  #
  # @param message [String] Optional message to check in response body
  def assert_conflict(message = nil)
    assert_response :conflict
    if @response.media_type == 'text/html' || @response.media_type == 'text/html; charset=utf-8'
      assert_select 'h1', /409: Conflict/
      assert_match(/#{Regexp.escape(message)}/, @response.body) if message
    end
  end
  
  # Assigns a role to a user
  def assign_role(user, role, resource = nil)
    user.grant(role, resource)
  end
  
  # Removes a role from a user
  def remove_role(user, role, resource = nil)
    user.revoke(role, resource)
  end
  
  # Creates and signs in a user with the specified role on a resource
#  def sign_in_as(role, resource = nil)
#    user = create(:user)
#    assign_role(user, role, resource) if role
#    sign_in_user(user)
#    user
#  end
end

# For controller tests
class ActionController::TestCase
  include Devise::Test::ControllerHelpers

  ActiveSupport.on_load(:action_controller) do
    Rails.application.reload_routes_unless_loaded
  end 

  setup do
    @request.env['devise.mapping'] = Devise.mappings[:user]
    @request.env['action_dispatch.cookies_serializer'] = :json
    
    # Set up Warden test mode
    # @request.env['warden'] = begin
    #  manager = Warden::Manager.new(nil) do |config|
    #    config.merge! Devise.warden_config
    #  end
    #  Warden::Proxy.new(@request.env, manager)
    #end
    
    # Set default locale for tests
  #  I18n.locale = I18n.default_locale
  end
  
  # Helper to set current project in session and cookies to match CurrentProjectConcern
  def set_current_project(project)
    @current_project = project
    session[:project_id] = project.id
    cookies.signed[:project_id] = project.id
  end
  
  ## Sign in helper that ensures the user is properly set in the session
  # def sign_in_user(user)
  #   sign_in(user, scope: :user)
  #   @current_user = user
  # end
end