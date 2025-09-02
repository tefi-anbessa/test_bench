FactoryBot.define do
  factory :project do
    code do
      last_code = Project.order(code: :asc).last&.code || 'AA'
      next_code = last_code.succ
      raise "No more project codes available (reached ZZ)" if next_code > 'ZZ'
      next_code
    end
    sequence(:title) { |n| "Project #{n}" }
    description { "A test project" }

  end
end
