class CreateCashBooks < ActiveRecord::Migration
  def self.up
    create_table :cash_books, :primary_key => :cash_book_id do |t|
      t.integer :cb_type_id
      t.string :cb_type
      t.date :cb_date
      t.string :cheque_number
      t.string :payee
      t.text :expenditure_details
      t.string :amount
      t.string :balance
      t.string :sheet_name
      t.integer :voided, :default => 0
      t.integer :voided_by
      t.date :date_voided
      t.timestamps
    end
  end

  def self.down
    drop_table :cash_books
  end
end
