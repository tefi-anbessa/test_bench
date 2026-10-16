
  
## Known Issues

### Tagable Validation - fixed

It is possible to create multiple tags referencing the same tagable element, despite the validations in place.

### Pagination - fixed

- **Issue**: The pagination system is not respecting the `per_page` parameter correctly.
- **Symptoms**:  
  - The URL updates with the selected `per_page` value
  - The page size selector shows the correct selected value
  - However, the number of items displayed remains at the default (20)
- **Affected Files**:  
  - `app/controllers/concerns/page_sizeable.rb`
  - `app/views/shared/_page_size_selector.html.erb`
  - `test/system/page_size_selector_test.rb`
- **Next Steps**:  
  - Check if the pagination is being overridden by any default scopes
  - Verify the pagination parameters are being passed correctly to the database query
  - Add more detailed logging to trace the pagination flow