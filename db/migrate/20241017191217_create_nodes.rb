class CreateNodes < ActiveRecord::Migration[6.0]
  def change
    create_table :nodes do |t|
      t.integer :identifier
      t.integer :state
      t.text :log
      t.text :neighbors

      t.timestamps
    end
  end
end
