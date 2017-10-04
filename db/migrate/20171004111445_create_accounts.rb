class CreateAccounts < ActiveRecord::Migration
  def self.up
    create_table :accounts, :primary_key => :account_id do |t|
      t.string :name
      t.string :code
      t.integer :voided, :default => 0
      t.integer :voided_by
      t.date :date_voided
      t.timestamps
    end
  end

  def self.down
    drop_table :accounts
  end
end
