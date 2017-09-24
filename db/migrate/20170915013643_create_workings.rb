class CreateWorkings < ActiveRecord::Migration
  def self.up
    create_table :workings, :primary_key => :workings_id do |t|
      t.string :name
      t.string :percent
      t.string :value
      t.integer :voided, :default => 0
      t.integer :voided_by
      t.date :date_voided
      t.timestamps
    end
  end

  def self.down
    drop_table :workings
  end
end
