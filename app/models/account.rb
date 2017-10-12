class Account < ActiveRecord::Base
  set_table_name :accounts
  set_primary_key :account_id

  validates_presence_of :name, :message => ' can not be blank'
  validates_presence_of :code, :message => ' can not be blank'
  
  validates_uniqueness_of :name, :message => ' already taken'
  validates_uniqueness_of :code, :message => ' already taken'

  default_scope :conditions => "#{self.table_name}.voided = 0"

  has_many :payment_vouchers, :foreign_key => :account_id
  has_many :incomes, :foreign_key => :account_id


  def self.new_account(params)
    account = Account.new
    account.name = params[:name]
    account.code = params[:code]
    return account
  end

  def self.edit_account(params)
    account = Account.find(params[:account_id])
    account.name = params[:name]
    account.code = params[:code]
    return account
  end

  def self.void_account(params)
    account = Account.find(params[:account_id])
    account.voided = 1
    account.voided_by = params[:voided_by]
    account.date_voided = Date.today
    return account
  end

  def has_associated_data?
    has_data = false
    has_data = true unless (self.payment_vouchers.blank?)
    has_data = true unless (self.incomes.blank?)
    return has_data
  end

end
