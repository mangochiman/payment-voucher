class Income < ActiveRecord::Base
  set_table_name :incomes
  set_primary_key :income_id

  validates_presence_of :details
  validates_presence_of :amount
  validates_presence_of :date
  
  validates_numericality_of :amount, :only_float => true

  default_scope :conditions => "#{self.table_name}.voided = 0"
  
  def self.new_income(params)
    income = Income.new
    income.details = params[:details]
    income.amount = params[:amount]
    income.date = params[:date]
    return income
  end

  def self.edit_income(params)
    income = Income.find(params[:income_id])
    income.details = params[:details]
    income.amount = params[:amount]
    income.date = params[:date]
    return income
  end

  def self.void_income(params)
    income = Income.find(params[:income_id])
    income.voided = 1
    income.voided_by = params[:voided_by]
    income.date_voided = Date.today
    return income
  end
end
