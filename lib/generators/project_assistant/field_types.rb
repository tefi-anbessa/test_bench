module ProjectAssistant
  module FieldTypes
    # Don't edit these unless rails introduces new types.
    RAILS_FIELD_TYPES = %w[
      string text integer bigint float decimal 
      datetime timestamp time date binary boolean primary_key jsonb
    ].freeze

    # Types can be added, but you will have to write the generator and test code to implement them.
    SPECIAL_FIELD_TYPES = %w[enum enum_translated].freeze

    # Don't edit this.
    VALID_FIELD_TYPES = (RAILS_FIELD_TYPES + SPECIAL_FIELD_TYPES).freeze

    # Options can be added, but you will have to write the generator and test code to implement them.
    VALID_OPTIONS = %w[required index uniq].freeze
    # required will add a validation to the model and a null: false in the migration.
    # index will add an index to the migration.
    # uniq will add a unique index to the migration.
    
    # These types (remaining after the subtraction) will include a searchable field in the index view.
    # You can tweak the list as required before generation, leave it as you found it.
    # Number fields are not really searchable for content, they generally require comparison operators. 
    # You can write your own search fields for ransack in the index view.
    SEARCHABLE_TYPES = (VALID_FIELD_TYPES - %w[
      integer bigint float decimal 
      datetime timestamp time date binary boolean primary_key
    ]).freeze
      
    # These types (remaining after the subtraction) will include a column in the index view.
    # The index view should only include fields that will easily tablulate.
    # You can tweak the list as required before generation, leave it as you found it.
    INDEX_TYPES = (VALID_FIELD_TYPES - %w[text primary_key binary jsonb]).freeze
  end
end