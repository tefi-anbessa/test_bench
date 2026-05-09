# Migrate Document Control to Core

Transition all DocumentControl module files (models, controllers, policies, views, tests, locales) to core namespace, eliminating the `DocumentControl` module entirely.

## Scope

### 1. Database Migrations (REQUIRED FIRST)

Create migrations to rename tables and foreign keys:

| Current Table | New Table |
|--------------|-----------|
| `document_control_doc_types` | `doc_types` |
| `document_control_issues` | `issues` |
| `document_control_source_formats` | `source_formats` |

| Current Foreign Key | New Foreign Key |
|--------------------|-----------------|
| `document_control_source_format_id` | `source_format_id` |
| `document_control_doc_type_id` (in documents table) | `doc_type_id` |

### 2. Models

**Move files:**
- `app/models/document_control/base.rb` → **DELETE**
- `app/models/document_control/doc_type.rb` → `app/models/doc_type.rb`
- `app/models/document_control/issue.rb` → `app/models/issue.rb`
- `app/models/document_control/source_format.rb` → `app/models/source_format.rb`

**Class changes:**
```ruby
# Before
module DocumentControl
  class DocType < Base
    belongs_to :discipline
    has_many :documents, dependent: :destroy
    
# After
class DocType < ApplicationRecord
  belongs_to :discipline
  has_many :documents, dependent: :destroy
```

### 3. Controllers

**Move files:**
- `app/controllers/document_control/doc_types_controller.rb` → `app/controllers/doc_types_controller.rb`
- `app/controllers/document_control/issues_controller.rb` → `app/controllers/issues_controller.rb`
- `app/controllers/document_control/source_formats_controller.rb` → `app/controllers/source_formats_controller.rb`

**Class changes:**
```ruby
# Before
module DocumentControl
  class DocTypesController < ApplicationController
    @q = @discipline.doc_types.ransack(params[:q])
    
# After
class DocTypesController < ApplicationController
  @q = @discipline.doc_types.ransack(params[:q])
```

### 4. Policies

**Move files:**
- `app/policies/document_control/doc_type_policy.rb` → `app/policies/doc_type_policy.rb`
- `app/policies/document_control/issue_policy.rb` → `app/policies/issue_policy.rb`
- `app/policies/document_control/source_format_policy.rb` → `app/policies/source_format_policy.rb`

**Class changes:**
```ruby
# Before
module DocumentControl
  class DocTypePolicy < ApplicationPolicy
    
# After
class DocTypePolicy < ApplicationPolicy
```

### 5. Views

**Move directories:**
- `app/views/document_control/doc_types/` → `app/views/doc_types/`
- `app/views/document_control/issues/` → `app/views/issues/`
- `app/views/document_control/source_formats/` → `app/views/source_formats/`

**View updates:**
- Change all `DocumentControl::DocType` references to `DocType`
- Update form helpers and model references

### 6. Routes

**Before:**
```ruby
namespace :document_control do
  resources :source_formats
end

resources :disciplines do
  namespace :document_control do
    resources :doc_types
  end
  resources :documents do
    namespace :document_control do
      resources :issues
    end
  end
end
```

**After:**
```ruby
resources :source_formats

resources :disciplines do
  resources :doc_types
  resources :documents do
    resources :issues
  end
end
```

### 7. Tests

**Move files:**
- `test/controllers/document_control/` → `test/controllers/`
- `test/models/document_control/` → `test/models/`
- `test/policies/document_control/` → `test/policies/`
- `test/system/document_control/` → `test/system/`

**Class changes:**
Remove `module DocumentControl` wrapping from all test classes.

**Factory updates:**
- `test/factories/document_control/` → `test/factories/`
- Change factory definitions from `factory :document_control_doc_type, class: DocumentControl::DocType` to `factory :doc_type`

### 8. Locales

**Move files:**
- `config/locales/document_control/en/` → `config/locales/core/en/`
- `config/locales/document_control/cn/` → `config/locales/core/cn/`
- `config/locales/document_control/km/` → `config/locales/core/km/`
- `config/locales/document_control/th/` → `config/locales/core/th/`

**Translation key changes:**
```yaml
# Before
en:
  activerecord:
    models:
      document_control:
        doc_type: "Document Type"
        
# After
en:
  activerecord:
    models:
      doc_type:
        one: "Document Type"
        other: "Document Types"
```

### 9. Constants

**Move:** `config/constants/document_control.yml` → integrate into `config/constants/role.yml` or main constants file.

### 10. References in Other Files

Update all references throughout codebase:
- `DocumentControl::DocType` → `DocType`
- `DocumentControl::Issue` → `Issue`
- `DocumentControl::SourceFormat` → `SourceFormat`
- `document_control/doc_types_path` → `doc_types_path`

## Execution Order

1. **Database migrations** (must run first)
2. **Models** (update inheritance and references)
3. **Routes** (simplify to core)
4. **Controllers** (remove namespace)
5. **Policies** (remove namespace)
6. **Views** (move and update references)
7. **Tests** (move and update class names)
8. **Factories** (update class references)
9. **Locales** (move and update keys)
10. **Constants** (merge into main)
11. **Cleanup** (remove empty document_control directories)

## Risk Assessment

**High Risk:**
- Database migrations - requires careful testing
- Model association references - must update all foreign key references

**Medium Risk:**
- Route changes - affects all URLs and path helpers
- Policy namespace changes - affects authorization

**Low Risk:**
- View file moves - mainly path updates
- Test file moves - isolated to test suite

## Rollback Plan

Keep migrations reversible with `reversible` blocks or separate down migrations. Test on staging database before production.

## Post-Migration Verification

- [ ] All routes work: `rails routes | grep -E "doc_type|issue|source_format"`
- [ ] All tests pass: `rails test`
- [ ] All system tests pass: `rails test:system`
- [ ] No DocumentControl references remain: `grep -r "DocumentControl" app/ config/ test/`
