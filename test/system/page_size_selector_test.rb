require "application_system_test_case"

class PageSizeSelectorTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers
  
  setup do
    # Create a test admin user using the factory
    @user = create(:user, :admin, email: 'test@example.com', name: 'Test User')
    sign_in @user
    
    # Clear any existing projects and create test data
    Project.destroy_all
    create_list(:project, 50)  # Create more projects to test pagination
  end
  
  test "page size selector changes number of items per page" do
    # The default page size is 20
    default_page_size = 20
    new_size = 25
    
    # Ensure we have enough projects to test pagination
    Project.destroy_all
    create_list(:project, 50)
    
    # Visit with explicit page size to ensure consistency
    visit projects_path(per_page: default_page_size)
    
    # Debug: Print current URL and page size
    puts "\n=== Initial Page Load ==="
    puts "Current URL: #{current_url}"
    puts "Query params: #{URI.parse(current_url).query}"
    puts "Number of items: #{all('table tbody tr').count}"
    
    # Verify initial state shows default number of items
    assert_selector "table tbody tr", count: default_page_size
    
    # The page size selector should be present and show the current page size
    assert_selector "select[name='per_page']"
    assert_equal default_page_size.to_s, find("select[name='per_page']").value
    
    # Debug: Print form details before submission
    form = find('form.page-size-form')
    puts "\n=== Before Form Submission ==="
    puts "Form action: #{form['action']}"
    puts "Form method: #{form['method']}"
    puts "Selected page size: #{find("select[name='per_page']").value}"
    
    # Select a different page size and submit the form
    select new_size.to_s, from: 'per_page'
    
    # Debug: Print form state after selection
    puts "\n=== After Selection ==="
    puts "Selected value: #{find("select[name='per_page']").value}"
    
    # Submit the form by clicking the button
    click_button 'Go'
    
    # Wait for the page to update and verify the URL changed
    assert_current_path(projects_path(per_page: new_size), wait: 5)
    
    # Debug: Print details after submission
    puts "\n=== After Form Submission ==="
    puts "Current URL: #{current_url}"
    puts "Query params: #{URI.parse(current_url).query}"
    puts "Number of items: #{all('table tbody tr').count}"
    
    # Verify the URL was updated with the new page size
    assert_current_path(projects_path(per_page: new_size), wait: 5)
    
    # Verify the selector shows the new page size
    assert_equal new_size.to_s, find("select[name='per_page']").value
    
    # Verify the number of items matches the new page size
    assert_selector "table tbody tr", count: new_size
    
    # Note: The actual number of items shown is controlled by the controller's pagination
    # which defaults to 20 items. Since we're testing the UI behavior of the selector,
    # we'll focus on verifying the URL and form field updates rather than the item count.
    # This is a known discrepancy between the UI and the actual pagination behavior.
  end
  
  test "page size selector is present and shows default items" do
    # The default page size is 20, and the selector should match this
    default_page_size = 20
    
    visit projects_path
    
    # Should show default number of items (20)
    assert_selector "table tbody tr", count: default_page_size
    
    # The page size selector should be present and show the current page size (20)
    assert_selector "select[name='per_page']"
    assert_equal default_page_size.to_s, find("select[name='per_page']").value
    
    # Verify standard page size options
    [10, 25, 50, 100].each do |size|
      assert_selector "select[name='per_page'] option[value='#{size}']"
    end
    
    # The selector should show the default page size (20)
    assert_equal default_page_size.to_s, find("select[name='per_page']").value
  end
  
  test "search functionality works with page size selector" do
    # Use a standard page size
    new_size = 50
    
    # Create a project with a unique name for testing search
    unique_project = create(:project, title: 'Unique Project 123', code: 'UP')
    
    # Search for the unique project
    visit projects_path
    fill_in 'q_code_or_title_or_description_cont', with: unique_project.title
    find('form#project_search button[type="submit"]').click
    
    # Should find exactly one result
    assert_selector "table tbody tr", count: 1
    assert_selector "td", text: unique_project.title
    
    # The search parameter should be preserved in the form
    assert_field 'q_code_or_title_or_description_cont', with: unique_project.title
    
    # The page size selector should still be present
    assert_selector "select[name='per_page']"
    
    # Changing the page size should preserve the search
    select new_size.to_s, from: 'per_page'
    click_button I18n.t('pagination.go')
    
    # Should still show the search result and preserve the search term
    assert_selector "table tbody tr", count: 1
    assert_selector "td", text: unique_project.title
    assert_field 'q_code_or_title_or_description_cont', with: unique_project.title
  end
end
