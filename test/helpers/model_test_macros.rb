# frozen_string_literal: true
# Class-level macros for model tests: enum keys, required and unique fields.
# Used by tagable and scaffold model tests. The model's own enum keys must match
# the Constants entry it reads, and every key needs a translation in every locale.
module ModelTestMacros
  extend ActiveSupport::Concern

  class_methods do
    # constants_path overrides the default per-model path for enums shared
    # between models (e.g. electrical.voltage_ratings).
    def test_enum_field(field, prefix: false, constants_path: nil)
      define_method("test_#{field}_enum_matches_constants") do
        path = constants_path ? constants_path.split(".") : [*@resource.class.name.underscore.split("/"), field]
        expected_keys = path.reduce(Constants) { |node, name| node.public_send(name) }.to_h.keys.map(&:to_s)
        actual_keys = @resource.class.public_send(field.to_s.pluralize).keys
        assert_equal expected_keys.sort, actual_keys.sort,
          "Expected enum #{field} keys to match Constants.#{path.join('.')}"
        actual_keys.each do |key|
          method = prefix ? "#{field}_#{key}?" : "#{key}?"
          assert_respond_to @resource, method,
            "Expected enum #{field} to respond to #{method}"
        end
      end
    end

    # Every enum key needs a label in every locale, otherwise views show a
    # "translation missing" string. See ApplicationRecord.human_enum_name.
    def test_enum_translations(*fields)
      define_method("test_enum_translations_present") do
        fields.each do |field|
          @resource.class.public_send(field.to_s.pluralize).keys.each do |key|
            I18n.available_locales.each do |locale|
              translation_key = "activerecord.attributes.#{@resource.class.model_name.i18n_key}.#{field.to_s.pluralize}.#{key}"
              assert I18n.exists?(translation_key, locale),
                "Missing #{locale} translation for #{translation_key}"
            end
          end
        end
      end
    end

    def test_required_fields(*fields)
      define_method("test_required_fields_presence") do
        fields.each do |field|
          model = @resource.dup
          model.public_send("#{field}=", nil)

          refute model.valid?, "Expected #{field} to be invalid when nil"
          assert_includes model.errors[field], I18n.t("errors.messages.blank"),
            "Expected #{field} to have a blank error, got #{model.errors[field].inspect}"
        end
      end
    end

    # belongs_to reports "must exist" (:required) rather than "blank".
    def test_required_associations(*fields)
      define_method("test_required_associations_presence") do
        fields.each do |field|
          model = @resource.dup
          model.public_send("#{field}=", nil)

          refute model.valid?, "Expected #{field} to be invalid when nil"
          assert_includes model.errors[field], I18n.t("errors.messages.required"),
            "Expected #{field} to have a required error, got #{model.errors[field].inspect}"
        end
      end
    end

    def test_unique_fields(*fields)
      define_method("test_unique_fields_uniqueness") do
        fields.each do |field|
          duplicate = build(@resource.class.model_name.singular)
          duplicate.public_send("#{field}=", @resource.public_send(field))

          refute duplicate.valid?, "Expected #{field} to be invalid when duplicated"
          assert_includes duplicate.errors[field], I18n.t("errors.messages.taken"),
            "Expected #{field} to have a taken error, got #{duplicate.errors[field].inspect}"
        end
      end
    end
  end
end
