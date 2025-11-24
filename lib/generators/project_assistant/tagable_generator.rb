# frozen_string_literal: true

require 'rails/generators/named_base'
require 'rails/generators/active_record/migration'

module ProjectAssistant
  class TagableGenerator < Rails::Generators::NamedBase
    include Rails::Generators::Migration
    source_root File.expand_path('templates', __dir__)

    argument :fields, type: :array, default: [], banner: 'field:type:options'
    
    class_option :module, type: :string, required: true,
      desc: 'Module namespace for the tagable type (e.g., electrical)'

    def initialize(args, *options)
      super
      @module_name = options.first[:module]&.underscore
      @tagable_name = name.underscore
      @tagable_class = name.camelize
      @fields = parse_fields(fields)
    end

    def create_migration_file
      migration_template 'migration.rb.erb', "db/migrate/#{migration_file_name}.rb"
    end

    private

    def parse_fields(field_args)
      field_args.map do |field_arg|
        name, type, *options = field_arg.split(':')
        {
          name: name,
          type: type,
          required: options.include?('required'),
          index: options.include?('index'),
          uniq: options.include?('uniq')
        }
      end
    end

    def migration_file_name
      "create_#{@module_name}_#{@tagable_name.pluralize}"
    end

    # Implement the required class method that returns the current migration version
    def self.next_migration_number(dirname)
      next_migration_number = current_migration_number(dirname) + 1
      ActiveRecord::Migration.next_migration_number(next_migration_number)
    end
  end
end
