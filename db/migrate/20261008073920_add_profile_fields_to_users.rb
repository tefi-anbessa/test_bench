class AddProfileFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :job_title, :string
    add_column :users, :time_zone, :string, default: "UTC", null: false
    add_column :users, :preferred_locale, :string
  end
end
