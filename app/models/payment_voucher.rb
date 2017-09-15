class PaymentVoucher < ActiveRecord::Base
  set_table_name :payment_vouchers
  set_primary_key :payment_voucher_id

  has_many :workings, :class_name => "PaymentVoucherWorkings",  :foreign_key => :payment_voucher_id
  default_scope :conditions => "#{self.table_name}.voided = 0"
  
  def self.new_payment_voucher(params)
     payment_voucher = PaymentVoucher.new
     payment_voucher.voucher_number = params[:voucher_number]
     payment_voucher.voucher_date = params[:voucher_date]
     payment_voucher.voucher_amount = params[:voucher_amount]
     payment_voucher.expenditure_details = params[:expenditure_details]
     payment_voucher.account_name = params[:account_name]
     payment_voucher.donor_code = params[:donor_code]
     payment_voucher.prepared_by = 1
     return payment_voucher
  end

  def self.edit_payment_voucher(params)
     payment_voucher = PaymentVoucher.find(params[:voucher_id])
     payment_voucher.voucher_number = params[:voucher_number]
     payment_voucher.voucher_date = params[:voucher_date]
     payment_voucher.voucher_amount = params[:voucher_amount]
     payment_voucher.expenditure_details = params[:expenditure_details]
     payment_voucher.account_name = params[:account_name]
     payment_voucher.donor_code = params[:donor_code]
     payment_voucher.prepared_by = 1
     return payment_voucher
  end

  def self.void_voucher(voucher_id)
    payment_voucher = PaymentVoucher.find(voucher_id)
    payment_voucher.voided = 1
    return payment_voucher
  end

  def self.todays_voucher_count
    count = PaymentVoucher.all.count
    return count
  end
end
