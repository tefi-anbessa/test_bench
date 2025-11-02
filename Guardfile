# A sample Guardfile
# More info at https://github.com/guard/guard#readme

## Uncomment and set this to only include directories you want to watch
# directories %w(app lib config test spec features) \
#  .select{|d| Dir.exist?(d) ? d : UI.warning("Directory #{d} does not exist")}

## Note: if you are using the `directories` clause above and you are not
## watching the project directory ('.'), then you will want to move
## the Guardfile to a watched dir and symlink it back, e.g.
#
#  $ mkdir config
#  $ mv Guardfile config/
#  $ ln -s config/Guardfile .
#
# and, you'll have to watch "config/Guardfile" instead of "Guardfile"

require "active_support/inflector"
require "json"
# Defines the matching rules for Guard.
guard :minitest, all_on_start: false do
  watch(%r{^test/(.*)/?(.*)_test\.rb$})
  watch('test/test_helper.rb') { 'test' }
  watch(%r{^test/factories/.*\.rb$}) { 'test/factories_test.rb' }
  watch('config/routes.rb') { interface_tests }
  watch(%r{app/views/layouts/*}) { interface_tests }

#  watch(%r{^test/fixtures/(.*?)\.yml$}) do |matches|
#    "test/models/#{matches[1].singularize}_test.rb"
#  end
  watch(%r{^app/models/(.*?)\.rb$}) do |matches|
    "test/models/#{matches[1].singularize}_test.rb"
  end
  watch('app/policies/application_policy.rb') do
    Dir['test/policies/*_test.rb']
  end
  
  watch(%r{^app/policies/(?!application_policy\.rb$)(.*?)\.rb$}) do |matches|
    "test/policies/#{matches[1].singularize}_test.rb"
  end
  watch(%r{^app/mailers/(.*?)\.rb$}) do |matches|
    "test/mailers/#{matches[1]}_test.rb"
  end
  watch(%r{^app/views/(.*)_mailer/.*$}) do |matches|
    "test/mailers/#{matches[1]}_mailer_test.rb"
  end
  watch(%r{^app/controllers/(.*?)_controller\.rb$}) do |matches|
    resource_tests(matches[1])
  end
  watch(%r{^app/views/([^/]*?)/.*\.html\.erb$}) do |matches|
    ["test/controllers/#{matches[1]}_controller_test.rb"] +
    integration_tests(matches[1])
  end
  watch(%r{^app/helpers/(.*?)_helper\.rb$}) do |matches|
    integration_tests(matches[1])
  end
  watch('app/views/layouts/application.html.erb') do
    'test/integration/site_layout_test.rb'
  end
  watch(%r{app/views/users/*}) do
    resource_tests('users')
  end

  watch(%r{app/views/devise/*}) do
    resource_tests('users')
  end

  # Watch tagable test patterns and controller concern for all tagable controller tests
  watch('test/helpers/tagable_test_patterns.rb') do
    tagable_controller_tests
  end
  watch('app/controllers/concerns/tagables_controller.rb') do
    tagable_controller_tests
  end


end

# Returns the integration tests corresponding to the given resource.
def integration_tests(resource = :all)
  if resource == :all
    Dir["test/integration/*"]
  else
    Dir["test/integration/#{resource}_*.rb"]
  end
end

# Returns all tests that hit the interface.
def interface_tests
  integration_tests << "test/controllers"
end

# Returns the controller tests corresponding to the given resource.
def controller_test(resource)
  "test/controllers/#{resource}_controller_test.rb"
end

# Returns all tests for the given resource.
def resource_tests(resource)
  integration_tests(resource) << controller_test(resource)
end

# Returns all tagable controller tests that use TagableTestPatterns
def tagable_controller_tests
  # Dynamically find tagable controller tests that use TagableTestPatterns
  tagable_tests = []

  # Get all tagable types from the model using Rails runner
  tagable_types = `cd #{Dir.pwd} && rails runner "puts Tag.tagable_types.to_json"`.strip

  # Parse the JSON response
  types = JSON.parse(tagable_types)

  # Check each tagable type for corresponding controller test
  types.each do |tagable_type|
    controller_name = tagable_type.underscore.pluralize
    test_file = "test/controllers/#{controller_name}_controller_test.rb"

    if File.exist?(test_file)
      # Check if the test file actually uses TagableTestPatterns
      test_content = File.read(test_file)
      if test_content.include?('TagableTestPatterns')
        tagable_tests << test_file
      end
    end
  end

  tagable_tests
end
