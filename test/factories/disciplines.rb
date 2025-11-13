# test/factories/disciplines.rb
FactoryBot.define do

  factory :discipline do
    association :project, factory: :project
    code { "code#{SecureRandom.hex(4)}" }
    name { "Discipline #{code}" }
    module_name { name.parameterize.underscore.camelize }
    sort_order { 100 }
    prefix_schema { { name: 'default' } }

    # For specific discipline types
    trait :elec do
      code { :elec }
      name { 'Electrical' }
      prefix_schema { { name: 'dim1' } }
    end

    trait :inst do
      code { :inst }
      name { 'Electrical' }
      prefix_schema { { name: 'isa51' } }
    end
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