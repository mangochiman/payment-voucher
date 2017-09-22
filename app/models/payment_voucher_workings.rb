class PaymentVoucherWorkings < ActiveRecord::Base
  set_table_name :payment_voucher_workings
  set_primary_key :payment_voucher_workings_id

  belongs_to :payment_voucher, :foreign_key => :payment_voucher_id
  belongs_to :workings, :foreign_key => :workings_id

  default_scope :conditions => "#{self.table_name}.voided = 0"
  
  def self.create_workings(payment_voucher_id, params)
    params[:workings].each do |working_id|
      payment_voucher_working = PaymentVoucherWorkings.new
      payment_voucher_working.payment_voucher_id = payment_voucher_id
      payment_voucher_working.workings_id = working_id
      payment_voucher_working.save
    end
  end
  
end
