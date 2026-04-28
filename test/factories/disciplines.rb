# test/factories/disciplines.rb
FactoryBot.define do

  factory :discipline do
    association :project, factory: :project
    swatch { Swatch.first || create(:swatch) }
    sequence(:name) { |n| "Factory Discipline #{format('%02d', n)}" }
    sequence(:label) { |n| "D#{format('%02d', n)}" }
    notes { Faker::Lorem.sentence }
    required_role { nil }
    sort_order { 100 }
    prefix_schema { { name: 'default' } }
  end
end

def generate_unique_code(project)
  return SecureRandom.alphanumeric(6).upcase unless project.present? && project.persisted?
  
  existing_codes = project.disciplines.pluck(:code)
  
  # Generate a random 6-letter code that's not already used
  loop do
    code = SecureRandom.alphanumeric(6).upcase
    return code unless existing_codes.include?(code)
  end

end