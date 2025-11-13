# test/factories/disciplines.rb
FactoryBot.define do

  factory :discipline do
    association :project, factory: :project
    code { "code#{SecureRandom.hex(4)}" }
    name { "Discipline #{code}" }
    module_name { name.parameterize.underscore.camelize }
    sort_order { 100 }
    prefix_schema { { name: :default } }

    # Standard disciplines from Constants
    Constants.disciplines.each do |disc|
      trait(disc[:code]) do
        code { disc[:code].to_s }
        name { disc[:name] }
        module_name { disc[:module] }
        sort_order { disc[:sort_order] }
        prefix_schema { disc[:prefix_schema] }
      end
    end
    # For specific discipline types
    trait :elec do
      code { :elec }
      name { 'Electrical' }
    end
    
    trait :mech do
      code { :mech }
      name { 'Mechanical' }
    end
    
    trait :inst do
      code { :inst }
      name { 'Instrumentation' }
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