# test/factories/import/batches.rb
FactoryBot.define do
  factory :import_batch, class: "Import::Batch" do
    association :user
    association :project
    discipline { nil }
    importer_key { "tags" }
    original_filename { "tags.csv" }
    file_data { "Tag Number,Discipline\nPT0001A,E\n" }
    column_mapping { {} }
  end
end
