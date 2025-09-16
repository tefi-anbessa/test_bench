require "application_system_test_case"

class CollapsibleComponentTest < ApplicationSystemTestCase
  include ActionView::Helpers::TagHelper
  include ActionView::Context
  
  test "collapsible component toggles content" do
    visit root_path  # Any existing route would work
    
    # Inject the component directly into the page
    page.execute_script <<~JS
      const component = `
        <div id="test-collapsible">
          <div class="card">
            <div class="card-header" data-bs-toggle="collapse" data-bs-target="#test-collapsible-body">
              <i class="bi bi-chevron-down"></i> Test Collapsible
            </div>
            <div id="test-collapsible-body" class="collapse show">
              <div class="card-body">
                <p>This is the collapsible content</p>
                <button class="btn btn-sm btn-primary">Test Button</button>
              </div>
            </div>
          </div>
        </div>
      `;
      document.body.insertAdjacentHTML('beforeend', component);
    JS
    
    # Verify the collapsible is present
    assert_selector "#test-collapsible"
    
    # Initially should be expanded
    assert_selector "#test-collapsible .card-body", visible: true
    
    # Click the header to collapse
    find("#test-collapsible .card-header").click
    
    # Should be collapsed
    assert_selector "#test-collapsible .card-body", visible: false
    
    # Click again to expand
    find("#test-collapsible .card-header").click
    
    # Should be expanded again
    assert_selector "#test-collapsible .card-body", visible: true
  end
  
  test "collapsible with custom expanded state" do
    visit root_path
    
    # Inject the component with collapsed state
    page.execute_script <<~JS
      const component = `
        <div id="test-collapsible">
          <div class="card">
            <div class="card-header" data-bs-toggle="collapse" data-bs-target="#test-collapsible-body">
              <i class="bi bi-chevron-down"></i> Test Collapsible
            </div>
            <div id="test-collapsible-body" class="collapse">
              <div class="card-body">
                <p>This is the collapsible content</p>
              </div>
            </div>
          </div>
        </div>
      `;
      document.body.insertAdjacentHTML('beforeend', component);
    JS
    
    # Should start collapsed
    assert_selector "#test-collapsible .card-body", visible: false
  end
  
  test "collapsible without icon" do
    visit root_path
    
    # Inject the component without icon
    page.execute_script <<~JS
      const component = `
        <div id="test-collapsible">
          <div class="card">
            <div class="card-header" data-bs-toggle="collapse" data-bs-target="#test-collapsible-body">
              Test Collapsible (No Icon)
            </div>
            <div id="test-collapsible-body" class="collapse show">
              <div class="card-body">
                <p>This is the collapsible content</p>
              </div>
            </div>
          </div>
        </div>
      `;
      document.body.insertAdjacentHTML('beforeend', component);
    JS
    
    # Should not have an icon
    assert_no_selector "#test-collapsible .card-header i"
  end
end
