# test/factories/import/mapping_presets.rb
FactoryBot.define do
  factory :import_mapping_preset, class: "Import::MappingPreset" do
    association :user
    importer_key { "tags" }
    column_mapping { { "Tag Number" => "full_tag", "Discipline" => "discipline" } }
  end
end
