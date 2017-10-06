require 'spreadsheet'
require 'writeexcel'
require "will_paginate"

class PaymentVoucher < ActiveRecord::Base
  set_table_name :payment_vouchers
  set_primary_key :payment_voucher_id

  #validates :voucher_amount, format: { with: /\A\d+\z/, message: "Integer only. No sign allowed." }
  validates_numericality_of :voucher_amount, :only_float => true
  validates_presence_of :voucher_number
  validates_uniqueness_of :voucher_number#, :message => ' already taken'
  validates_uniqueness_of :cheque_number, :allow_nil => true, :allow_blank => true

  belongs_to :account, :foreign_key => :account_id
  has_many :workings, :class_name => "PaymentVoucherWorkings",  :foreign_key => :payment_voucher_id
  default_scope :conditions => "#{self.table_name}.voided = 0"

  def account_name
    self.account.name rescue nil
  end

  def donor_code
    self.account.code rescue nil
  end

  def self.new_payment_voucher(params)
    payment_voucher = PaymentVoucher.new
    payment_voucher.voucher_number = params[:voucher_number]
    payment_voucher.voucher_date = params[:voucher_date]
    payment_voucher.voucher_amount = params[:voucher_amount]
    payment_voucher.expenditure_details = params[:expenditure_details]
    payment_voucher.payee = params[:payee]
    payment_voucher.account_id = params[:account_id]
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
    payment_voucher.account_id = params[:account_id]
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

  def self.void_voucher(params)
    payment_voucher = PaymentVoucher.find(params[:voucher_id])
    payment_voucher.voided = 1
    payment_voucher.voided_by = params[:voided_by]
    payment_voucher.date_voided = Date.today
    return payment_voucher
  end

  def self.todays_voucher_count
    count = PaymentVoucher.all.count
    return count
  end

  def self.my_vouchers(user, params)
    per_page = PaymentVoucher.per_page
    my_vouchers = PaymentVoucher.paginate(:conditions => ["prepared_by =? ",
        user.user_id], :page => params[:page], :per_page => per_page,
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

  def update_cashbook
    payment_voucher = self
    file_path = "#{Rails.root}/doc/cash_book.xls"
    new_cashbook_path = "#{Rails.root}/doc/cash_book2.xls"
    rows = PaymentVoucher.cash_book_rows(file_path)
    #current_cash_book_balance = PaymentVoucher.current_cash_book_balance(rows)
    PaymentVoucher.create_cash_book(new_cashbook_path, rows, payment_voucher)
    #check_for_cheque number duplicates
    rows = PaymentVoucher.cash_book_rows(new_cashbook_path)
    cheque_numbers = []
    uniq_rows = []
    i = 0
    rows.reverse.each do |row|
      cheque_number = row[1]
      cheque_number = i if cheque_number.blank?
      next if cheque_numbers.include?(cheque_number)
      uniq_rows << row
      cheque_numbers << cheque_number
      i = i + 1
    end
    rows = uniq_rows.reverse
    PaymentVoucher.create_cash_book(new_cashbook_path, rows, payment_voucher, false) #remove duplicates
    `cp #{new_cashbook_path} #{file_path}`
  end

  def self.create_cash_book(new_cashbook_path, rows, payment_voucher, new_entry = true)
    workbook = WriteExcel.new(new_cashbook_path)
    worksheet  = workbook.add_worksheet
    worksheet.set_column(0, 0, 15)
    worksheet.set_column(0, 1, 20)
    worksheet.set_column(0, 2, 20)
    worksheet.set_column(0, 3, 20)
    worksheet.set_column(0, 4, 20)
    worksheet.set_column(0, 5, 20)
    # Add and define a format
    format = workbook.add_format
    format.set_bold
    format.set_align('right')

    red_color = workbook.add_format
    red_color.set_color('red')

    bold_format = workbook.add_format
    bold_format.set_bold
    bold_format.set_align('center')

    number_format = workbook.add_format
    number_format.set_num_format('#,##0.00') # 1,234.56

    number_red_format = workbook.add_format
    number_red_format.set_color('red')
    number_red_format.set_num_format('#,##0.00')

    number_red_format_condition  = workbook.add_format
    number_red_format_condition.set_num_format('#,##0.00')
    number_red_format_condition.set_num_format('#,##0.00;[RED]-#,##0.00')

    row_pos = 0

    rows.each do |row|
      cell_0 = row[0]; cell_1 = row[1]; cell_2 = row[2]; cell_3 = row[3];
      cell_4 = row[4]; cell_5 = row[5]
      
      if (row_pos == 0) #first row. Header
        worksheet.write(row_pos, 0, cell_0, bold_format)
        worksheet.write(row_pos, 1, cell_1, bold_format)
        worksheet.write(row_pos, 2, cell_2, bold_format)
        worksheet.write(row_pos, 3, cell_3, bold_format)
        worksheet.write(row_pos, 4, cell_4, bold_format)
        worksheet.write(row_pos, 5, cell_5, bold_format)
      end

      if (row_pos == 1) #second row. Opening Balance
        worksheet.write(row_pos, 0, cell_0)
        worksheet.write(row_pos, 1, cell_1)
        worksheet.write(row_pos, 2, cell_2)
        worksheet.write(row_pos, 3, cell_3)
        worksheet.write(row_pos, 4, cell_4)
        worksheet.write(row_pos, 5, cell_5, number_format)
      end

      if (row_pos > 1) #Transactions
        formulae = "=F#{row_pos}+E#{row_pos + 1}"
        worksheet.write(row_pos, 0, cell_0)
        worksheet.write(row_pos, 1, cell_1)
        worksheet.write(row_pos, 2, cell_2)
        worksheet.write(row_pos, 3, cell_3)

        if cell_4.to_f < 0
          worksheet.write(row_pos, 4, cell_4, number_red_format) #negative numbers
        else
          worksheet.write(row_pos, 4, cell_4, number_format) #positive numbers
        end
        
        worksheet.write_formula(row_pos, 5,  formulae, number_red_format_condition)
      end

      row_pos = row_pos + 1
    end

    if (new_entry)
      cheque_number = payment_voucher.cheque_number
      voucher_date = payment_voucher.voucher_date.to_date.strftime("%d.%m.%Y")
      payable_amount = payment_voucher.payable_amount
      expenditure_details = payment_voucher.expenditure_details
      payee_details = payment_voucher.payee

      new_row_pos = row_pos
      formulae = "=F#{new_row_pos}+E#{new_row_pos + 1}"
      worksheet.write(new_row_pos, 0, voucher_date)
      worksheet.write(new_row_pos, 1, cheque_number)
      worksheet.write(new_row_pos, 2, payee_details)
      worksheet.write(new_row_pos, 3, expenditure_details)
      worksheet.write(new_row_pos, 4, -payable_amount.to_i, number_red_format)
      worksheet.write_formula(new_row_pos, 5,  formulae, number_red_format_condition)
    end

    # write to file
    workbook.close
  end

  def self.cash_book_rows(file_path)
    cash_book = Spreadsheet.open file_path
    cash_book_sheet = cash_book.worksheet 0
    total_rows = cash_book_sheet.count
    rows = []
    current_balance = 0
    0.upto(total_rows - 1) do |i|
      cell_0 = cash_book_sheet.rows[i][0]
      cell_1 = cash_book_sheet.rows[i][1]
      cell_2 = cash_book_sheet.rows[i][2]
      cell_3 = cash_book_sheet.rows[i][3]
      cell_4 = cash_book_sheet.rows[i][4]
      if (i == 0)
        cell_5 = cash_book_sheet.rows[i][5]
      end

      if i == 1
        current_balance =  cell_5.to_f
      end
      if (i ==1)
        cell_5 = cash_book_sheet.rows[i][5]
      end

      if (i > i)
        cell_5 = ""
      end
      if current_balance > 0
        current_balance = current_balance.to_f + cell_4.to_f
      end
      rows << [cell_0, cell_1, cell_2, cell_3, cell_4, cell_5]
    end

    return rows
  end

  def self.vouchers_by_date_range(start_date, end_date, params)
    per_page = PaymentVoucher.per_page
    payment_vouchers = PaymentVoucher.paginate(:conditions => ["DATE(created_at) >= ? AND DATE(created_at) <= ?",
        start_date, end_date], :page => params[:page], :per_page => per_page,
      :order => "payment_voucher_id DESC")
    return payment_vouchers
  end

  def self.vouchers_by_user(user, start_day_date, end_day_date)
    payment_vouchers = PaymentVoucher.find(:all, :conditions => ["prepared_by =? AND
      DATE(created_at) >= ? AND DATE(created_at) <= ?", 
        user.user_id, start_day_date, end_day_date], :order => "payment_voucher_id DESC",:limit => 10)
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

  def self.current_cash_book_balance(data)
    current_balance = 0
    total_rows = data.length
    0.upto(total_rows - 1) do |i|
      payable_amount = data[i][4].to_f
      if i == 1
        current_balance =  data[i][5] #opening balance
      end
      if i > 1
        current_balance = current_balance.to_f + payable_amount
      end
    end
    
    return current_balance
  end

  def self.per_page
    per_page = 10
    return per_page
  end

end
