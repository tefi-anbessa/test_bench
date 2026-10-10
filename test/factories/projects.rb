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

    # Defaults to every standard discipline, matching the old
    # create_all_for_project behaviour - most tests assume any standard
    # discipline they need already exists on @project. Override with a
    # specific list to test the new selective behaviour itself.
    discipline_codes { Discipline.standard_options.keys.map(&:to_s) }
  end
end
