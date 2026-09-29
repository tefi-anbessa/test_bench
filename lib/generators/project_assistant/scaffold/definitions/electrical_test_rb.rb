# Ruby-format equivalent of electrical_test.yml - same fields, same options,
# covering every type and option the generator supports. Named distinctly
# from electrical_test.yml (not electrical_test.rb) because
# ScaffoldHelper#load_definition prefers a .yml file over a .rb file of the
# same base name, so a same-named .rb file here would never actually load.
{
  name: { type: :string, required: true, index: true, valid: "Test name" },
  description: { type: :text, valid: "Factory generated description" },
  selector: { type: :enum, keys: %w[s1 s2 s3] },
  status: { type: :enum_translated, keys: %w[draft published archived] },
  sort_order: { type: :integer, index: true, valid: 100, unique: true },
  power: { type: :float, precision: 4, units: "m", si: true, valid: 5.555 },
  money: { type: :decimal, precision: 5, scale: 2, valid: 1.55 },
  switch: { type: :boolean },
  birthday: { type: :date },
  created: { type: :datetime },
  flex_field: { type: :jsonb },
  code: { type: :string, uniq: true },
  blob: { type: :binary },
  parent: { type: :references, required: false },
  owner: { type: :belongs_to, required: true }
}
