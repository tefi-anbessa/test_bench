class CreateMotors < ActiveRecord::Migration[7.0]
  def change
    create_table :motors do |t|
      t.string :motor_type
      t.string :frame_size
      t.integer :poles
      t.string :ingress_protection
      t.float :speed_rated

      t.timestamps
    end
  end
end
