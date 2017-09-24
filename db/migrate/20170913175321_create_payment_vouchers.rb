class CreatePaymentVouchers < ActiveRecord::Migration
  def self.up
    create_table :payment_vouchers, :primary_key => :payment_voucher_id do |t|
      t.string :voucher_number
      t.string :cheque_number
      t.string :payee
      t.date :voucher_date
      t.string :voucher_amount
      t.text :expenditure_details
      t.string :account_name
      t.string :donor_code
      t.string :prepared_by
      t.integer :voided, :default => 0
      t.integer :voided_by
      t.date :date_voided
      t.timestamps
    end
  end

  def self.down
    drop_table :payment_vouchers
  end
end
