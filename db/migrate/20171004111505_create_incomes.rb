class CreateIncomes < ActiveRecord::Migration
  def self.up
    create_table :incomes, :primary_key => :income_id do |t|
      t.string :details
      t.string :amount
      t.date :date
      t.integer :voided, :default => 0
      t.integer :voided_by
      t.date :date_voided
      t.timestamps
    end
  end

  def self.down
    drop_table :incomes
  end
end
