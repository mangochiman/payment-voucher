class Workings < ActiveRecord::Base
  set_table_name :workings
  set_primary_key :workings_id

  has_many :payment_vouchers, :through => :payment_voucher_workings
  has_many :payment_voucher_workings, :class_name => "PaymentVoucherWorkings", :foreign_key => "workings_id"

  validates_presence_of :name, :message => ' can not be blank'
  validates_numericality_of :percent, :only_float => true
  default_scope :conditions => "#{self.table_name}.voided = 0"

  def self.new_workings(params)
     workings = Workings.new
     workings.name = params[:name]
     workings.percent = params[:percent]
     workings.value = params[:value]
     return workings
  end

  def self.edit_workings(params)
     workings = Workings.find(params[:workings_id])
     workings.name = params[:name]
     workings.percent = params[:percent]
     workings.value = params[:value]
     return workings
  end

  def self.void_workings(workings_id)
    workings = Workings.find(workings_id)
    workings.voided = 1
    return workings
  end

  def self.per_page
    per_page = 10
    return per_page
  end
  
end
