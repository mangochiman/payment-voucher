require 'spreadsheet'

class CashBook < ActiveRecord::Base
  set_table_name :cash_books
  set_primary_key :cash_book_id

  default_scope :conditions => "#{self.table_name}.voided = 0"
  
  def self.create_or_update_cash_book(params, cb_type)
    cash_book = CashBook.find(:last, :conditions => ["cb_type_id =? AND cb_type =?",
        params[:cb_type_id], cb_type])
    
    if cash_book.blank?
      cash_book = CashBook.new
      cash_book.cb_type_id = params[:cb_type_id]
      cash_book.cb_type = cb_type
      cash_book.save
    end

    return cash_book
  end

  def self.load_initial_cashbook_data
    file_path = "#{Rails.root}/doc/cash_book.xls"
    cash_book = Spreadsheet.open file_path
    available_sheets = cash_book.worksheets.map(&:name)

    available_sheets.each do |sheet_name|
      cash_book_rows = PaymentVoucher.initial_cash_book_rows(file_path, sheet_name)
      i = 0
      cash_book_rows.each do |row|
        i = i + 1
        next if i == 1 #Header
        date = row[0]
        cheque_number = row[1]
        payee = row[2]
        expenditure_details = row[3]
        amount = row[4]
        balance = row[5]
        cb_type = "voucher"
        cb_type = "income" if amount.to_f >= 0

        cb = CashBook.new
        cb.cb_type = cb_type
        cb.cb_date = date
        cb.cheque_number = cheque_number
        cb.payee = payee
        cb.expenditure_details = expenditure_details
        cb.amount = amount
        cb.balance = balance
        cb.sheet_name = sheet_name
        cb.save

      end
    end

    return available_sheets
  end

  def self.reset_cash_book_rows(user_id)
    cash_book_rows = CashBook.all
    cash_book_rows.each do |row|
      row.voided = 1
      row.voided_by = user_id
      row.date_voided = Date.today
      row.save
    end
    return cash_book_rows
  end

  def self.rows_by_sheet
    data = {}
    cash_book_rows = CashBook.all
    cash_book_rows.each do |row|
      if row.cb_type_id.blank?
        cb_date = row.cb_date
        cheque_number = row.cheque_number
        payee = row.payee
        expenditure_details = row.expenditure_details
        amount = row.amount
        balance = row.balance
        sheet_name = row.sheet_name
        data[sheet_name] = [] if data[sheet_name].blank?
        data[sheet_name] << [{
            "cb_date" => cb_date,
            "cheque_number" => cheque_number,
            "payee" => payee,
            "expenditure_details" => expenditure_details,
            "amount" => amount.to_f,
            "balance" => balance.to_f
          }]
      else
        
        if row.cb_type.to_s.match(/voucher/i)
          payment_voucher = PaymentVoucher.find(row.cb_type_id)
          cb_date = payment_voucher.voucher_date
          cheque_number = payment_voucher.cheque_number
          payee = payment_voucher.payee
          expenditure_details = payment_voucher.expenditure_details
          amount = "-#{payment_voucher.payable_amount}".to_f
          sheet_name = payment_voucher.donor_code
          balance = ""
     
          data[sheet_name] = [] if data[sheet_name].blank?
          data[sheet_name] << [{
              "cb_date" => cb_date,
              "cheque_number" => cheque_number,
              "payee" => payee,
              "expenditure_details" => expenditure_details,
              "amount" => amount.to_f,
              "balance" => balance.to_f
            }]

        end
        
        if row.cb_type.to_s.match(/income/i)
          income = Income.find(row.cb_type_id)
          cb_date = income.date
          cheque_number = ""
          payee = ""
          expenditure_details = income.details
          amount = income.amount.to_f
          sheet_name = income.donor_code
          balance = ""

          data[sheet_name] = [] if data[sheet_name].blank?
          data[sheet_name] << [{
              "cb_date" => cb_date,
              "cheque_number" => cheque_number,
              "payee" => payee,
              "expenditure_details" => expenditure_details,
              "amount" => amount.to_f,
              "balance" => balance.to_f
            }]
        end
        
      end
    end
    
    return data
  end

  def self.work_sheets
    work_sheets = CashBook.all.collect{|cb|cb.sheet_name}.uniq.compact
    cash_book_rows = CashBook.all
    work_sheets = []
    
    cash_book_rows.each do |row|
      unless row.sheet_name.blank?
        work_sheets << row.sheet_name
      end
      unless row.cb_type_id.blank?
        if row.cb_type.to_s.match(/voucher/i)
          payment_voucher = PaymentVoucher.find(row.cb_type_id) rescue nil
          work_sheets << payment_voucher.donor_code unless payment_voucher.blank?
        end

        if row.cb_type.to_s.match(/income/i)
          income = Income.find(row.cb_type_id) rescue nil
          work_sheets << income.donor_code unless income.blank?
        end
      end
    end

    return work_sheets.uniq.compact
  end

  def self.void_cash_book_record(params, cb_type_id, cb_type)
    cash_book = CashBook.find(:last , :conditions => ["cb_type_id =? AND cb_type =?",
        cb_type_id, cb_type])
    
    unless cash_book.blank?
      cash_book.voided = 1
      cash_book.voided_by = params[:voided_by]
      cash_book.date_voided = Date.today
      cash_book.save
    end

    return cash_book
  end

  def self.sheet_book_balance(sheet_name)
    data = CashBook.rows_by_sheet[sheet_name]
    total_balance = 0
    data.each do |values|
      v = values[0]
      amount = v["amount"].to_f
      balance = v["balance"].to_f
      total_balance += (amount + balance)
    end
    return total_balance
  end
  
end
