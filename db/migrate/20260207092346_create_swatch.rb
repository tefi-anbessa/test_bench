class CreateSwatch < ActiveRecord::Migration[8.0]
  def change
    create_table :swatches do |t|
      t.string :name, null: false
      t.string :bg, null: false
      t.string :text, null: false
      t.string :form_bg, null: false
      t.string :form_field, null: false
      t.string :card_bg, null: false
      t.string :card_header_bg, null: false
      t.string :card_border, null: false
      t.string :badge_bg, null: false
      t.string :badge_text, null: false
      t.string :link_text, null: false
      t.string :link_hover, null: false
      t.timestamps
    end
    add_index :swatches, :name, unique: true
  end
end