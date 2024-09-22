class CreateDisciplines < ActiveRecord::Migration[7.0]
  def change
    create_table :disciplines, primary_key: :code, id: { type: :string, limit: 1 } do |t|
      t.string :name

      t.timestamps
    end
  end
end
