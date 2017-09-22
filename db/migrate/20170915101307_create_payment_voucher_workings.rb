class CreatePaymentVoucherWorkings < ActiveRecord::Migration
  def self.up
    create_table :payment_voucher_workings, :primary_key => :payment_voucher_workings_id do |t|
      t.integer :payment_voucher_id
      t.integer :workings_id
      t.integer :voided, :default => 0
      t.timestamps
    end
  end

  def self.down
    drop_table :payment_voucher_workings
  end
end
