## Sheet1
| Unnamed: 0 | Unnamed: 1 | Unnamed: 2 | Unnamed: 3 | Unnamed: 4 |
| --- | --- | --- | --- | --- |
| NaN | Model name change | NaN | NaN | NaN |
| NaN | NaN | Generate migration | bash: | rails g migration change\_old\_name\_to\_new\_name |
| NaN | NaN | Edit migration and save | Insert line after def change: | rename\_table :old\_name, :new\_name |
| NaN | NaN | Run migration | bash: | rails db:migrate |
| NaN | NaN | NaN | NaN | NaN |
| NaN | NaN | Edit files: rename classes | In file: | Edit: |
| NaN | NaN | NaN | app/controllers/namespace/old\_names\_controller.rb | class NewNamesController < … |
| NaN | NaN | NaN | app/models/namespace/old\_name.rb | class NewName < … |
| NaN | NaN | NaN | app/policies/namespace/old\_name\_policy.rb | class NewNamePolicy < … |
| NaN | NaN | NaN | test/controllers/namespace/old\_names\_controller\_test.rb | class NewNamesControllerTest < … |
| NaN | NaN | NaN | test/models/namespace/old\_name\_model\_test.rb | class NewNameModelTest < … |
| NaN | NaN | NaN | test/policies/namespace/old\_name\_policy\_test.rb | class NewNamePolicyTest < … |
| NaN | NaN | NaN | test/system/namespace/old\_names\_system\_test.rb | class NewNamesSystemTest < … |
| NaN | NaN | NaN | NaN | NaN |
| NaN | NaN | Rename files | From: | To: |
| NaN | NaN | NaN | app/controllers/namespace/old\_names\_controller.rb | app/controllers/namespace/new\_names\_controller.rb |
| NaN | NaN | NaN | app/models/namespace/old\_name.rb | app/models/namespace/new\_name.rb |
| NaN | NaN | NaN | app/policies/namespace/old\_name\_policy.rb | app/policies/namespace/new\_name\_policy.rb |
| NaN | NaN | NaN | test/controllers/namespace/old\_names\_controller\_test.rb | test/controllers/namespace/new\_names\_controller\_test.rb |
| NaN | NaN | NaN | test/factories/namespace/old\_names.rb | test/factories/namespace/new\_names.rb |
| NaN | NaN | NaN | test/models/namespace/old\_name\_model\_test.rb | test/models/namespace/new\_name\_model\_test.rb |
| NaN | NaN | NaN | test/policies/namespace/old\_name\_policy\_test.rb | test/policies/namespace/new\_name\_policy\_test.rb |
| NaN | NaN | NaN | test/system/namespace/old\_names\_system\_test.rb | test/system/namespace/new\_names\_system\_test.rb |
| NaN | NaN | NaN | NaN | NaN |
| NaN | NaN | Rename folder | app/views/namespace/old\_name | app/views/namespace/new\_name |
| NaN | NaN | NaN | NaN | NaN |
| NaN | NaN | NaN | From: | To: |
| NaN | NaN | Edit files: model associations | app/models/namespace/new\_name.rb | NaN |
| NaN | NaN | NaN | belongs\_to :old\_name, | belongs\_to :new\_name, |
| NaN | NaN | NaN | has\_many :old\_names | has\_many :new\_names |
| NaN | NaN | NaN | etc. | NaN |
| NaN | NaN | Edit files: controller | def old\_name\_params | def new\_name\_params |
| NaN | NaN | NaN | instance variable names for member and collection | NaN |
| NaN | NaN | NaN | check controllers of associated models for setup of collections | NaN |
| NaN | NaN | Edit files: views | global substitution of all affected instance variables (check individually) | NaN |
| NaN | NaN | Edit files: routes | config/routes.rb | NaN |
| NaN | NaN | NaN | namespace : namespace do | namespace : namespace do |
| NaN | NaN | NaN | resources :old\_name | resources :new\_name |
| NaN | NaN | Edit files: factory | test/factories/namespace/new\_names.rb | NaN |
| NaN | NaN | NaN | factory :namespace\_old\_name, class: 'Namespace::OldName' do | factory :namespace\_new\_name, class: 'Namespace::NewName' do |
| NaN | NaN | Edit files: config/constants | config/constants/namespace.yml | NaN |
| NaN | NaN | NaN | namespace: | namespace: |
| NaN | NaN | NaN | old\_name: | new\_name: |
| NaN | NaN | Edit files: config/locales | <config/locales/namespace/en/en.namespace.models.yml> | NaN |
| NaN | NaN | NaN | en: | en: |
| NaN | NaN | NaN | activerecord: | activerecord: |
| NaN | NaN | NaN | models: | models: |
| NaN | NaN | NaN | namespace/old\_name: | namespace/new\_name: |
| NaN | NaN | NaN | … | … |
| NaN | NaN | NaN | attributes: | attributes: |
| NaN | NaN | NaN | namespace/old\_name: | namespace/new\_name: |
| NaN | NaN | NaN | <config/locales/namespace/en/en.namespace.views.yml> | NaN |
| NaN | NaN | NaN | en: | en: |
| NaN | NaN | NaN | namespace: | namespace: |
| NaN | NaN | NaN | old\_name: | new\_name: |
| NaN | NaN | NaN | (Repeat for all locales) | NaN |
| NaN | NaN | NaN | NaN | NaN |
| NaN | NaN | Global search for: | table name: namespace\_old\_name, @namespace\_old\_name | NaN |
| NaN | NaN | NaN | singular name: old\_name, @old\_name | NaN |
| NaN | NaN | NaN | plural name: old\_names, @old\_names | NaN |
| NaN | NaN | NaN | class name: OldName, Namespace::OldName | NaN |
| NaN | NaN | NaN | NaN | NaN |
| NaN | NaN | NaN | NaN | NaN |
| NaN | Module name change: | NaN | NaN | NaN |
| NaN | NaN | Generate migration | bash: | rails g migration change\_old\_namespace\_widget\_to\_new\_namespace\_widget |
| NaN | NaN | Edit migration | Insert line after def change: | rename\_table :old\_namespace\_widget, :new\_namespace\_widget |
| NaN | NaN | Run migration | bash: | rails db:migrate |
| NaN | NaN | NaN | NaN | NaN |
| NaN | NaN | Edit files: | In file: | Edit: |
| NaN | NaN | NaN | app/controllers/old\_namespace/widgets\_controller.rb | module NewNamespace |
| NaN | NaN | NaN | app/models/old\_namespace/widget.rb | module NewNamespace |
| NaN | NaN | NaN | app/models/old\_namespace/base.rb | module NewNamespace |
| NaN | NaN | NaN | app/policies/old\_namespace/widget\_policy.rb | module NewNamespace |
| NaN | NaN | NaN | test/controllers/old\_namespace/widgets\_controller\_test.rb | module NewNamespace |
| NaN | NaN | NaN | test/models/old\_namespace/widget\_model\_test.rb | module NewNamespace |
| NaN | NaN | NaN | test/policies/old\_namespace/widget\_policy\_test.rb | module NewNamespace |
| NaN | NaN | NaN | test/system/old\_namespace/widgets\_system\_test.rb | module NewNamespace |
| NaN | NaN | NaN | NaN | NaN |
| NaN | NaN | Rename folders | From: | To: |
| NaN | NaN | NaN | app/controllers/old\_namespace | app/controllers/new\_namespace |
| NaN | NaN | NaN | app/helpers/old\_namespace | app/helpers/new\_namespace |
| NaN | NaN | NaN | app/models/old\_namespace | app/models/new\_namespace |
| NaN | NaN | NaN | app/policies/old\_namespace | app/policies/new\_namespace |
| NaN | NaN | NaN | app/views/old\_namespace | app/views/new\_namespace |
| NaN | NaN | NaN | test/controllers/old\_namespace | test/controllers/new\_namespace |
| NaN | NaN | NaN | test/factories/old\_namespace | test/factories/new\_namespace |
| NaN | NaN | NaN | test/models/old\_namespace | test/models/new\_namespace |
| NaN | NaN | NaN | test/policies/old\_namespace | test/policies/new\_namespace |
| NaN | NaN | NaN | test/system/old\_namespace | test/system/new\_namespace |
| NaN | NaN | NaN | config/locales/old\_namespace | config/locales/new\_namespace |
| NaN | NaN | NaN | NaN | NaN |
| NaN | NaN | Rename files | app/models/old\_namespace.rb | app/models/new\_namespace.rb |
| NaN | NaN | NaN | config/constants/old\_namespace.yml | config/constants/new\_namespace.yml |
| NaN | NaN | NaN | config/locales/old\_namespace/en/en.old\_namespace.models.yml | config/locales/new\_namespace/en/en.new\_namespace.models.yml |
| NaN | NaN | NaN | config/locales/old\_namespace/en/en.old\_namespace.views.yml | config/locales/new\_namespace/en/en.new\_namespace.views.yml |
| NaN | NaN | NaN | config/locales/old\_namespace/en/en.old\_namespace.yml | config/locales/new\_namespace/en/en.new\_namespace.yml |
| NaN | NaN | NaN | (Repeat for all locales) | NaN |
| NaN | NaN | NaN | NaN | NaN |
| NaN | NaN | Edit files: model | <app/models/new\_namespace/widget.rb> | NaN |
| NaN | NaN | - associations | belongs\_to :old\_namespace\_widget, | belongs\_to :new\_namespace\_widget, |
| NaN | NaN | NaN | has\_many :old\_namespace\_widgets, | has\_many :new\_namespace\_widgets, |
| NaN | NaN | NaN | etc. | NaN |
| NaN | NaN | - enum definitions | enum :field\_name, Constants.old\_namespace.widget.field\_name.to\_h | enum :field\_name, Constants.new\_namespace.widget.field\_name.to\_h |
| NaN | NaN | NaN | NaN | NaN |
| NaN | NaN | NaN | NaN | NaN |
| NaN | NaN | Edit files: factory | <test/factories/new\_namespace/widgets.rb> | NaN |
| NaN | NaN | NaN | factory :old\_namespace\_widget, class: 'OldNamespace::Widget' do | factory :new\_namespace\_widget, class: 'NewNamespace::Widget' do |
| NaN | NaN | NaN | NaN | NaN |
| NaN | NaN | NaN | NaN | NaN |
| NaN | NaN | NaN | NaN | NaN |
| NaN | NaN | NaN | NaN | NaN |
| NaN | NaN | NaN | NaN | NaN |
| NaN | NaN | NaN | NaN | NaN |
| NaN | NaN | NaN | NaN | NaN |
| NaN | NaN | Edit files: config/locales | <config/locales/electrical/en/en.new\_namespace.models.yml> | NaN |
| NaN | NaN | NaN | en: | en: |
| NaN | NaN | NaN | activerecord: | activerecord: |
| NaN | NaN | NaN | models: | models: |
| NaN | NaN | NaN | old\_namespace/widget: | new\_namespace/widget: |
| NaN | NaN | NaN | … | … |
| NaN | NaN | NaN | attributes: | attributes: |
| NaN | NaN | NaN | old\_namespace/widget: | new\_namespace/widget: |
| NaN | NaN | NaN | <config/locales/namespace/en/en.namespace.views.yml> | NaN |
| NaN | NaN | NaN | en: | en: |
| NaN | NaN | NaN | old\_namespace: | new\_namespace: |
| NaN | NaN | NaN | widget: | widget: |
| NaN | NaN | NaN | NaN | NaN |
| NaN | NaN | NaN | <config/locales/namespace/en/en.namespace.yml> | NaN |
| NaN | NaN | NaN | en: | en: |
| NaN | NaN | NaN | old\_namespace: | new\_namespace: |
| NaN | NaN | NaN | (Repeat for all locales) | NaN |
| NaN | NaN | NaN | NaN | NaN |
| NaN | NaN | Repeat all preceding steps as applicable, for every model in the namespace. | NaN | NaN |
| NaN | NaN | NaN | NaN | NaN |
| NaN | NaN | Edit files: routes | <config/routes.rb> | NaN |
| NaN | NaN | NaN | namespace : old\_namespace do | namespace : new\_namespace do |
| NaN | NaN | NaN | NaN | NaN |
| NaN | NaN | Edit files: config/constants | <config/constants/new\_namespace.yml> | NaN |
| NaN | NaN | NaN | old\_namespace: | new\_namespace: |
| NaN | NaN | NaN | widget: | widget: |