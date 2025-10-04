# lib/constant/load.rb

# frozen_string_literal: true

module Constant
  class Load

    def initialize(path)
      @path = path
    end

    def call
      Dir.glob(File.join(path, '*.yml')).each_with_object({}) do |file_path, hash|
        begin
          loaded_data = YAML.load_file(file_path)
          hash.merge!(loaded_data)
        rescue Psych::SyntaxError => e
          raise "YAML syntax error in #{file_path}: #{e.message}"
        rescue StandardError => e
          Rails.logger.error "Failed to load constants from #{file_path}: #{e.message}"
          next
        end
      end
    end

    private

    attr_reader :path

  end
end
