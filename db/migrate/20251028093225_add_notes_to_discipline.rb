class AddNotesToDiscipline < ActiveRecord::Migration[8.0]
  def change
    add_column :disciplines, :notes, :text
  end
end
