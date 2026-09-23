module ProjectAssistant
  module Shared
    module FieldTypes
      # Don't edit these unless rails introduces new types.
      RAILS_FIELD_TYPES = %i[
        string text integer bigint float decimal 
        datetime timestamp time date binary boolean primary_key jsonb
      ].freeze

      # Types can be added, but you will have to write the generator and test code to implement them.
      SPECIAL_FIELD_TYPES = %i[references belongs_to enum enum_translated].freeze

      # Don't edit this.
      VALID_FIELD_TYPES = (RAILS_FIELD_TYPES + SPECIAL_FIELD_TYPES).freeze

      # Options can be added, but you will have to write the generator and test code to implement them.
      VALID_OPTIONS = %i[required index uniq unique valid precision scale units si step max min].freeze
      # required will add a validation to the model and a null: false in the migration.
      # index will add an index to the migration.
      # uniq or unique will add a unique index to the migration.
      # valid will provide the given value as a default to the test factory
      # precision and scale will provide those options to decimal and float types
      # units and si (boolean) will be used in presentation of decimal or float numbers.
      # step, max and min will be used in number fields for forms.
      
      # These types (remaining after the subtraction) will include a searchable field in the index view.
      # You can tweak the list as required before generation, leave it as you found it.
      # Number fields are not really searchable for content, they generally require comparison operators. 
      # You can write your own search fields for ransack in the index view.
      SEARCHABLE_TYPES = (VALID_FIELD_TYPES - %i[
        references belongs_to integer bigint float decimal 
        datetime timestamp time date binary boolean primary_key
      ]).freeze
        
      # These types (remaining after the subtraction) will include a column in the index view.
      # The index view should only include fields that will easily tabulate.
      # You can tweak the list as required before generation, leave it as you found it.
      INDEX_TYPES = (VALID_FIELD_TYPES - %i[primary_key binary]).freeze

      # These types will generate an associated drop down card in show view.
      ASSOCIATION_TYPES = %i[references belongs_to]
    end
  end
end