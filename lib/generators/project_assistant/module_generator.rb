# lib/generators/project_assistant/module_generator.rb
require "rails/generators/named_base"

module ProjectAssistant
  class ModuleGenerator < Rails::Generators::NamedBase
    source_root File.expand_path("templates", __dir__)

    def create_module_structure
      @module_name = name.underscore
      @module_class = name.camelize

      # Check for existing module structure
      if should_abort?("app/#{@module_name}") || 
         should_abort?("test/#{@module_name}") ||
         should_abort?("app/models/#{@module_name}.rb")
        return
      end

      # Create app directory structure
      %w[controllers helpers models policies views].each do |dir|
        dir_path = File.join(destination_root, "app", @module_name, dir)
        empty_directory(dir_path) unless File.directory?(dir_path)
        keep_file = File.join(dir_path, ".keep")
        create_file(keep_file, verbose: false) unless File.exist?(keep_file)
      end

      # Create test directory structure
      %w[controllers factories models policies system].each do |dir|
        dir_path = File.join(destination_root, "test", @module_name, dir)
        empty_directory(dir_path) unless File.directory?(dir_path)
        keep_file = File.join(dir_path, ".keep")
        create_file(keep_file, verbose: false) unless File.exist?(keep_file)
      end

      # Create locales directory
      dest_dir = File.join(destination_root, 'config', 'locales', @module_name)
      
      if File.exist?(dest_dir)
        if Rails.env.test?
          puts "[TEST] Would prompt to overwrite locale directory: #{dest_dir}"
          # In test environment, proceed without asking
        else
          return unless yes?("Locale directory #{dest_dir} already exists. Overwrite? [y/N]")
        end
      else
        empty_directory(dest_dir, verbose: false)
      end
      
      # Create YAML files for each available locale
      I18n.available_locales.each do |locale|
        lang = locale.to_s
        
        # Create language subdirectory
        lang_dir = File.join(dest_dir, lang)
        empty_directory(lang_dir) unless File.directory?(lang_dir)
        
        # Create [locale].[module_name].yml for general translations
        general_file = File.join(dest_dir, "#{lang}.#{@module_name}.yml")
        create_file(general_file, <<~YAML, verbose: false) unless File.exist?(general_file)
          # General translations for #{@module_name} module in #{lang}
          #{lang}:
            #{@module_name}:
        YAML
        
        # Create [locale].[module_name].models.yml and [locale].[module_name].views.yml
        %w[models views].each do |file_type|
          file_path = File.join(dest_dir, "#{lang}.#{@module_name}.#{file_type}.yml")
          create_file(file_path, <<~YAML, verbose: false) unless File.exist?(file_path)
            # #{@module_name} #{file_type} translations for #{lang}
            #{lang}:
              #{file_type}:
                #{@module_name}:
          YAML
          
          # Create language-specific subdirectories for models and views
          file_type_dir = File.join(lang_dir, file_type)
          empty_directory(file_type_dir) unless File.directory?(file_type_dir)
        end
      end
      # Base model
      template "base.rb.erb", "app/#{@module_name}/base.rb"
      template "module.rb.erb", "app/models/#{@module_name}.rb"

      # Autoload paths
      inject_into_file "config/application.rb", 
        after: "class Application < Rails::Application\n" do
        <<~RUBY
          # Autoload module directories
          config.autoload_paths += %W(\#{config.root}/app/#{@module_name} \#{config.root}/app/#{@module_name}/**/)
        RUBY
      end

      # Routes
      route "namespace :#{@module_name} do\n    # Add your routes here\n  end"
    end
    
    private
    
    def should_abort?(path)
      full_path = Rails.root.join(path)
      if File.exist?(full_path)
        if Rails.env.test?
          puts "[TEST] Would prompt to overwrite: #{full_path}"
          return false  # In test environment, always proceed without asking
        else
          unless yes?("#{full_path} already exists. Overwrite? [y/N]")
            say "Module '#{@module_name}' generation aborted.", :red
            return true
          end
        end
      end
      false
    end
  end
end