class PaymentVoucher < ActiveRecord::Base
  set_table_name :payment_vouchers
  set_primary_key :payment_voucher_id

  #validates :voucher_amount, format: { with: /\A\d+\z/, message: "Integer only. No sign allowed." }
  validates_numericality_of :voucher_amount, :only_float => true
  has_many :workings, :class_name => "PaymentVoucherWorkings",  :foreign_key => :payment_voucher_id
  default_scope :conditions => "#{self.table_name}.voided = 0"
  
  def self.new_payment_voucher(params)
    payment_voucher = PaymentVoucher.new
    payment_voucher.voucher_number = params[:voucher_number]
    payment_voucher.voucher_date = params[:voucher_date]
    payment_voucher.voucher_amount = params[:voucher_amount]
    payment_voucher.expenditure_details = params[:expenditure_details]
    payment_voucher.payee = params[:payee]
    payment_voucher.account_name = params[:account_name]
    payment_voucher.donor_code = params[:donor_code]
    payment_voucher.prepared_by = params[:user_id]
    return payment_voucher
  end

  def self.edit_payment_voucher(params)
    payment_voucher = PaymentVoucher.find(params[:voucher_id])
    payment_voucher.voucher_number = params[:voucher_number]
    payment_voucher.voucher_date = params[:voucher_date]
    payment_voucher.voucher_amount = params[:voucher_amount]
    payment_voucher.expenditure_details = params[:expenditure_details]
    payment_voucher.payee = params[:payee]
    payment_voucher.account_name = params[:account_name]
    payment_voucher.donor_code = params[:donor_code]
    return payment_voucher
  end

  def updating_workings(params)
    payment_voucher = self
    workings = payment_voucher.workings
    
    ActiveRecord::Base.transaction do
      workings.each do |working|
        working.voided = 1
        working.save
      end

      params[:workings].each do |working_id|
        payment_voucher_workings = PaymentVoucherWorkings.new
        payment_voucher_workings.payment_voucher_id = payment_voucher.payment_voucher_id
        payment_voucher_workings.workings_id = working_id
        payment_voucher_workings.save
      end
    end
    
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

  def self.my_vouchers(user)
    my_vouchers = PaymentVoucher.find(:all, :conditions => ["prepared_by =? ", user.user_id],
      :order => "payment_voucher_id DESC")
    return my_vouchers
  end

  def self.search_by_voucher_number(voucher_number)
    search_results = PaymentVoucher.find(:all, :conditions => ["voucher_number =? ", voucher_number],
      :order => "payment_voucher_id DESC")
    return search_results
  end

  def self.search_by_donor_code(donor_code)
    search_results = PaymentVoucher.find(:all, :conditions => ["donor_code =? ", donor_code],
      :order => "payment_voucher_id DESC")
    return search_results
  end

  def self.search_by_account_name(account_name)
    search_results = PaymentVoucher.find(:all, :conditions => ["account_name LIKE (?) ", "%#{account_name}%"],
      :order => "payment_voucher_id DESC")
    return search_results
  end

  def update_cheque_number(params)
    payment_voucher = self
    payment_voucher.cheque_number = params[:cheque_number]
    return payment_voucher
  end

  def self.vouchers_by_date_range(start_date, end_date)
    payment_vouchers = PaymentVoucher.find(:all, :conditions => ["DATE(created_at) >= ? AND DATE(created_at) <= ?",
        start_date, end_date])
    return payment_vouchers
  end

  def payable_amount
    payment_voucher =self
    workings = payment_voucher.workings
    sub_total = payment_voucher.voucher_amount.to_f
    
    workings.each do |payment_voucher_working|
      plus_minus = payment_voucher_working.workings.value
      workings_percent = payment_voucher_working.workings.percent
      calculated_value = ((workings_percent.to_f/100) * payment_voucher.voucher_amount.to_f)
      payable_amount_string = "#{sub_total}#{plus_minus}#{calculated_value}"
      sub_total = eval(payable_amount_string)
    end

    payable_amount = sub_total
    return payable_amount
  end
  
end
