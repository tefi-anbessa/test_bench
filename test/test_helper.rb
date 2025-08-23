ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require 'minitest/reporters'
require 'factory_bot_rails'
require 'database_cleaner/active_record'

# Keep test output clean but visible
Rails.logger.level = Logger::WARN

# Load test support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

# Simple test output
Minitest::Reporters.use! [
  Minitest::Reporters::ProgressReporter.new(color: true)
]

# Configure DatabaseCleaner
DatabaseCleaner.strategy = :transaction
DatabaseCleaner.clean_with(:truncation)

class ActiveSupport::TestCase
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

  # Add more helper methods to be used by all tests here...
  include FactoryBot::Syntax::Methods
  include Devise::Test::IntegrationHelpers
  
  # Returns the current user
  def current_user
    @current_user
  end
  
  # Returns the current project
  def current_project
    @current_project
  end
  
  # Sets the current project in the session
  # @param project [Project] The project to set as current
  def set_current_project(project)
    @current_project = project
    # Also set in session if controller test
    if defined?(controller) && controller.respond_to?(:session)
      session[:current_project_id] = project.id
    end
  end

  # Assert that the response is an unauthorized access
  # This can be either:
  # 1. A 403 Forbidden response, or
  # 2. A redirect to root with an unauthorized flash message
  def assert_unauthorized
    if response.redirect?
      assert_redirected_to root_path
      assert_not flash.empty?
      assert_equal I18n.t('pundit.not_authorized'), flash[:alert]
    else
      assert_response :forbidden
    end
  end
  
  # Signs in a user for integration tests
  def sign_in_user(user = nil)
    @current_user = user || create(:user)
    sign_in @current_user
  end
  
  # Signs in an admin user for integration tests
  def sign_in_admin(admin = nil)
    @current_user = admin || create(:user, :admin)
    sign_in @current_user
  end
  
  # Signs out the current user
  def sign_out_user
    sign_out :user
    @current_user = nil
  end
  
  # Assigns a role to a user
  def assign_role(user, role, resource = nil)
    user.add_role(role, resource)
  end
  
  # Removes a role from a user
  def remove_role(user, role, resource = nil)
    user.remove_role(role, resource)
  end
  
  # Creates and signs in a user with the specified role on a resource
  def sign_in_as(role, resource = nil)
    user = create(:user)
    assign_role(user, role, resource) if role
    sign_in_user(user)
    user
  end
end
