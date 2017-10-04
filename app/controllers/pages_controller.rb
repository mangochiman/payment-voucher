require 'spreadsheet'
require 'writeexcel'
require "will_paginate"
class PagesController < ApplicationController
  skip_before_filter :authenticate_user, :only => [:login, :authenticate, :reset_password, :voucher_downloadable, :print_voucher]
  before_filter :lock_screen_when_activated, :except => [:lock_screen, :unlock_screen, :login, :logout, :reset_password]
  
  def login
    session.delete(:screen_locked) if session[:screen_locked]
    if request.post?
      user = User.find_by_username(params['username'])
      logged_in_user = User.authenticate(params[:username], params[:password])
      if logged_in_user
        session[:user] = user
        redirect_to("/") and return
      else
        flash[:error] = "Invalid username or password"
        redirect_to("/login") and return
      end
    end
    
    render :layout => false
  end

  def logout
    reset_session #Destroy all sessions
    redirect_to("/login") and return
  end
  
  def home
    @page_header = "Dashboard"
    start_day_date = Date.today
    end_day_date = Date.today

    day_name = start_day_date.strftime("%A")
    start_week_date = Date.today.beginning_of_week - 1.day #sunday
    if day_name.match(/Sunday/i)
      start_week_date = Date.today
    end
    end_week_date = start_week_date + 6.days #saturday
    start_month_date = Date.today.beginning_of_month
    end_month_date = Date.today.end_of_month

    start_year_date = Date.today.beginning_of_year
    end_year_date = Date.today.end_of_year

    @payment_vouchers = PaymentVoucher.vouchers_by_user(session[:user], start_day_date, end_day_date)
    @todays_vouchers = PaymentVoucher.vouchers_by_date_range(start_day_date, end_day_date, params).total_entries
    @this_weeks_vouchers = PaymentVoucher.vouchers_by_date_range(start_week_date, end_week_date, params).total_entries
    @this_months_vouchers = PaymentVoucher.vouchers_by_date_range(start_month_date, end_month_date, params).total_entries
    @this_year_vouchers = PaymentVoucher.vouchers_by_date_range(start_year_date, end_year_date, params).total_entries
  end

  def todays_vouchers
    start_day_date = Date.today
    end_day_date = Date.today
    @page_header = "Today's vouchers (#{start_day_date.strftime('%a, %d-%b-%Y')})"
    @payment_vouchers = PaymentVoucher.vouchers_by_date_range(start_day_date, end_day_date, params)
  end

  def this_weeks_vouchers
    start_day_date = Date.today
    day_name = start_day_date.strftime("%A")
    start_week_date = Date.today.beginning_of_week - 1.day #sunday
    if day_name.match(/Sunday/i)
      start_week_date = Date.today
    end
    end_week_date = start_week_date + 6.days #saturday
    @page_header = "This week's vouchers (#{start_week_date.strftime('%a, %d-%b-%Y')} - #{end_week_date.strftime('%a, %d-%b-%Y')})"
    @payment_vouchers = PaymentVoucher.vouchers_by_date_range(start_week_date, end_week_date, params)
  end

  def this_months_vouchers
    start_month_date = Date.today.beginning_of_month
    end_month_date = Date.today.end_of_month
    @page_header = "This month's vouchers (#{start_month_date.strftime('%a, %d-%b-%Y')} - #{end_month_date.strftime('%a, %d-%b-%Y')})"
    @payment_vouchers = PaymentVoucher.vouchers_by_date_range(start_month_date, end_month_date, params)
  end

  def this_years_vouchers
    start_year_date = Date.today.beginning_of_year
    end_year_date = Date.today.end_of_year
    @page_header = "This years's vouchers (#{start_year_date.strftime('%a, %d-%b-%Y')} - #{end_year_date.strftime('%a, %d-%b-%Y')})"
    @payment_vouchers = PaymentVoucher.vouchers_by_date_range(start_year_date, end_year_date, params)
  end

  def new_voucher_menu
    @page_header = "New payment voucher"
    @workings = Workings.find(:all)
    if request.post?
      if params[:workings].blank?
        flash[:error] = "Voucher creation failed. Workings were not selected"
        redirect_to("/new_voucher_menu") and return
      end
      new_payment_voucher = PaymentVoucher.new_payment_voucher(params)
      if new_payment_voucher.save
        PaymentVoucherWorkings.create_workings(new_payment_voucher.payment_voucher_id, params)
        flash[:notice] = "New payment voucher was saved"
        redirect_to("/view_voucher_menu") and return
      else
        flash[:error] = "Failed to save the payment voucher"
        redirect_to("/new_voucher_menu") and return
      end
    end
  end

  def edit_voucher_menu
    @page_header = "Edit payment voucher"
    per_page = PaymentVoucher.per_page
    @payment_vouchers = PaymentVoucher.paginate(:page => params[:page], :per_page => per_page,
      :order => "payment_voucher_id DESC")
  end

  def edit_this_voucher
    @payment_voucher = PaymentVoucher.find(params[:voucher_id])
    @page_header = "Editing payment voucher #:  #{@payment_voucher.voucher_number}"
    @workings = Workings.find(:all)
    @my_workings = @payment_voucher.workings
    
    if request.post?
      if params[:workings].blank?
        flash[:error] = "Record update failed. No workings were selected"
        redirect_to("/edit_this_voucher?voucher_id=#{params[:voucher_id]}") and return
      end
      edit_payment_voucher = PaymentVoucher.edit_payment_voucher(params)
      if edit_payment_voucher.save
        edit_payment_voucher.updating_workings(params)
        flash[:notice] = "Payment voucher was updated"
        redirect_to("/edit_voucher_menu") and return
      else
        flash[:error] = edit_payment_voucher.errors.full_messages.join('<br />')
        redirect_to("/edit_this_voucher?voucher_id=#{params[:voucher_id]}") and return
      end
    end
  end

  def view_this_voucher
    @payment_voucher = PaymentVoucher.find(params[:voucher_id])
    @workings = @payment_voucher.workings
    sub_total = @payment_voucher.voucher_amount.to_f
    @user_details = ""
    user = User.find(@payment_voucher.prepared_by) rescue nil
    unless user.blank?
      fname = user.first_name.capitalize.to_s rescue user.first_name
      lname = user.last_name.capitalize.to_s rescue user.last_name
      @user_details = (fname + " " + lname)
    end
    
    @workings.each do |payment_voucher_working|
      plus_minus = payment_voucher_working.workings.value
      workings_percent = payment_voucher_working.workings.percent
      calculated_value = ((workings_percent.to_f/100) * @payment_voucher.voucher_amount.to_f)
      payable_amount_string = "#{sub_total}#{plus_minus}#{calculated_value}"
      #raise payable_amount_string.inspect
      sub_total = eval(payable_amount_string)
      #raise sub_total.inspect
      #raise calculated_value.inspect
    end
    @payable_amount = sub_total
    @page_header = "Viewing payment voucher #:  #{@payment_voucher.voucher_number}"
  end
  
  def view_voucher_menu
    @page_header = "View payment voucher"
    per_page = PaymentVoucher.per_page
    @payment_vouchers = PaymentVoucher.paginate(:page => params[:page], :per_page => per_page,
      :order => "payment_voucher_id DESC")
  end

  def void_voucher_menu
    @page_header = "Void payment voucher"
    per_page = PaymentVoucher.per_page
    @payment_vouchers = PaymentVoucher.paginate(:page => params[:page], :per_page => per_page,
      :order => "payment_voucher_id DESC")
    
    if request.post?
      void_voucher = PaymentVoucher.void_voucher(params)
      if void_voucher.save
        flash[:notice] = "Voucher #: #{void_voucher.voucher_number} has been voided"
      else
        flash[:error] = void_voucher.errors.full_messages.join('<br />')
      end
      redirect_to("/void_voucher_menu")
    end
  end

  def new_account_details
    @page_header = "New account details"
    if request.post?
      new_account = Account.new_account(params)
      if new_account.save
        flash[:notice] = "New account was created"
        redirect_to("/new_account_details") and return
      else
        flash[:error] = new_account.errors.full_messages.join('<br />')
        redirect_to("/new_account_details") and return
      end
    end
  
  end

  def edit_account_details
    @page_header = "Edit account details"
    per_page = Workings.per_page
    @accounts = Account.paginate(:page => params[:page], :per_page => per_page)
  end

  def edit_this_account
    @account = Account.find(params[:account_id])
    @page_header = "Editing account name:  #{@account.name}"
    if request.post?
      edit_account = Account.edit_account(params)
      if edit_account.save
        flash[:notice] = "Account was updated"
        redirect_to("/edit_account_details") and return
      else
        flash[:error] = edit_account.errors.full_messages.join('<br />')
        redirect_to("/edit_this_account?account_id=#{params[:account_id]}") and return
      end
    end
  end
  
  def view_account_details
    @page_header = "View account details"
    per_page = Workings.per_page
    @accounts = Account.paginate(:page => params[:page], :per_page => per_page)
  end

  def void_account_details
    @page_header = "Void account details"
    per_page = Workings.per_page
    @accounts = Account.paginate(:page => params[:page], :per_page => per_page)
    if request.post?
      void_account = Account.void_account(params)
      if void_account.save
        flash[:notice] = "Account name: #{void_account.name} has been voided"
      else
        flash[:error] = void_account.errors.full_messages.join('<br />')
      end
      redirect_to("/view_account_details")
    end
  end

  def new_income
    @page_header = "New income"
  end

  def edit_income
    @page_header = "Edit income"
  end

  def edit_this_income
    @income = Income.find(params[:income_id])
    @page_header = "Editing income:  #{@income.details}"
  end
  
  def view_income
    @page_header = "View income"
  end

  def void_income
    @page_header = "Void income"
  end

  def new_user
    @page_header = "New user"
    @roles = User.roles
    if request.post?
      password = params[:password]
      password_confirm = params[:confirm_password]

      if (password != password_confirm)
        flash[:error] = "Password Mismatch"
        redirect_to("/new_user") and return
      end
      user = User.new_user(params)

      if user.save
        UserRole.create_user_role(user, params)

        flash[:notice] = "Account creation was successful"
        redirect_to("/new_user") and return
      else
        flash[:error] = user.errors.full_messages.join('<br />')
        redirect_to("/new_user") and return
      end
    end
  end

  def update_user_profile
    @page_header = "Editing profile"
    if request.post?
      update_user = User.update_user(session[:user], params)
      if (update_user.save)
        flash[:notice] = "Profile update was succesful"
        redirect_to("/personal_details") and return
      else
        flash[:error] = update_user.errors.full_messages.join('<br />')
        redirect_to("/update_user_profile") and return
      end
    end
  end

  def change_password
    @page_header = "Change password"
    user = session[:user]
    if request.post?
      if (User.authenticate(user.username, params[:old_password]))
        if (params[:new_password] == params[:confirm_password])
          user.password = User.encrypt(params[:new_password], user.salt)
          if (user.save)
            flash[:notice] = "You have successfully updated your password. Your new password is <b>#{params[:new_password]}</b>"
            redirect_to("/personal_details") and return
          else
            flash[:error] = user.errors.full_messages.join('<br />')
            redirect_to("/change_password") and return
          end
        else
          flash[:error] = "Password update failed. New password and confirmation password does not match"
          redirect_to("/change_password") and return
        end
      else
        flash[:error] = "Password update failed. Old password is not correct"
        redirect_to("/change_password") and return
      end
    end
  end
  
  def view_users
    @page_header = "View Users"
    per_page = User.per_page
    @users = User.paginate(:page => params[:page], :per_page => per_page)
  end

  def remove_user
    @page_header = "Remove user"
    per_page = User.per_page
    @users = User.paginate(:page => params[:page], :per_page => per_page)
    
    if request.post?
      user = User.find(params[:user_id])
      user.void_user(params)
      if user.save
        flash[:notice] = "#{user.username} has been voided"
      else
        flash[:error] = user.errors.full_messages.join('<br />')
      end
      redirect_to("/remove_user") and return 
    end
  end

  def reset_password
    render :layout => false
  end
  
  def personal_details
    @page_header = "Personal Details"
  end
  
  def payments_report
    @page_header = "Payments Report"
  end

  def new_workings
    @page_header = "New Workings"
    @values = [["Addition", "+"], ["Subtraction", "-"]]
    if request.post?
      new_workings = Workings.new_workings(params)
      if new_workings.save
        flash[:notice] = "New workings was saved"
        redirect_to("/view_workings")
      else
        flash[:error] = new_workings.errors.full_messages.join('<br />')
        redirect_to("/new_workings")
      end
    end
  end

  def edit_workings
    @page_header = "Edit Workings"
    per_page = Workings.per_page
    @workings = Workings.paginate(:page => params[:page], :per_page => per_page)
  end

  def edit_this_workings
    @workings = Workings.find(params[:workings_id])
    @page_header = "Editing #{@workings.name}"
    @values = [["Addition", "+"], ["Subtraction", "-"]]

    if request.post?
      edit_workings = Workings.edit_workings(params)
      if edit_workings.save
        flash[:notice] = "New workings was updated"
        redirect_to("/view_workings")
      else
        flash[:error] = edit_workings.errors.full_messages.join('<br />')
        redirect_to("/edit_this_workings?workings_id=#{params[:workings_id]}")
      end
    end

  end

  def view_workings
    @page_header = "View Workings"
    per_page = Workings.per_page
    @workings = Workings.paginate(:page => params[:page], :per_page => per_page)
  end

  def void_workings
    @page_header = "Void Workings"
    per_page = Workings.per_page
    @workings = Workings.paginate(:page => params[:page], :per_page => per_page)

    if request.post?
      void_workings = Workings.void_workings(params)
      if void_workings.save
        flash[:notice] = "Workings : #{void_workings.name} has been voided"
      else
        flash[:error] = void_workings.errors.full_messages.join('<br />')
      end
      
      redirect_to("/void_workings")
    end
  end

  def lock_screen
    session[:screen_locked] = true
    http_referrer = request.env["HTTP_REFERER"]

    unless (http_referrer.blank? || (http_referrer.match(/lock_screen/i)))
      session[:referrer] = request.referrer
    end

    render :layout => false
  end

  def unlock_screen
    logged_in_user = User.authenticate(session[:user].username, params[:password])

    if logged_in_user
      session.delete(:screen_locked) if session[:screen_locked]
      (redirect_to("#{session[:referrer]}") and return) unless session[:referrer].blank?
      redirect_to("/") and return
    else
      #flash[:error] = "Invalid password"
      #request.referrer = session[:referrer]
      #return
      redirect_to("/lock_screen") and return
    end
  end

  def my_vouchers
    @page_header = "My vouchers"
    @my_vouchers = PaymentVoucher.my_vouchers(session[:user], params)
  end

  def search_vouchers_menu
    @page_header = "Search vouchers"
    @search_results = []
    if (params[:voucher_number])
      voucher_number = params[:voucher_number]
      @search_results = PaymentVoucher.search_by_voucher_number(voucher_number)
    end

    unless (params[:search_type].blank?)
      if (params[:search_type] == 'donor_code')
        donor_code = params[:search_words]
        @search_results = PaymentVoucher.search_by_donor_code(donor_code)
      end

      if (params[:search_type] == 'account_name')
        account_name = params[:search_words]
        @search_results = PaymentVoucher.search_by_account_name(account_name)
      end
    end
    
  end

  def update_cheque_number
    @page_header = "Update cheque number"
    @payment_voucher = PaymentVoucher.find(params[:voucher_id])
    if request.post?
      updated_voucher = @payment_voucher.update_cheque_number(params)
      if updated_voucher.save
        flash[:notice] = "Cheque number has been updated"
        redirect_to("/view_this_voucher?voucher_id=#{params[:voucher_id]}") and return
      else
        flash[:error] = updated_voucher.errors.full_messages.join('<br />')
        redirect_to("/update_cheque_number?voucher_id=#{params[:voucher_id]}") and return
      end
    end
  end

  def update_cash_book_menu
    @payment_voucher = PaymentVoucher.find(params[:voucher_id])
    @page_header = "Updating cash book for voucher #:  #{@payment_voucher.voucher_number}"
    session.delete(:cash_balance) if session[:cash_balance]
    session.delete(:voucher_id) if session[:voucher_id]

    if request.post?
      file_path = "#{Rails.root}/doc/cash_book.xls"
      unless (File.file?(file_path))
        flash[:error]= "Cash book not found on the server. Upload the file first and try again"
        redirect_to("/update_cash_book_menu?voucher_id=#{params[:voucher_id]}") and return
      end
      new_cashbook_path = "#{Rails.root}/doc/cash_book2.xls"
      rows = cash_book_rows(file_path)
      current_cash_book_balance = PaymentVoucher.current_cash_book_balance(rows)

      if params[:confirm_update].blank? #only do this when this variable is blank?
        if (current_cash_book_balance < 0)
          session[:cash_balance] = current_cash_book_balance
          session[:voucher_id] = params[:voucher_id]
          redirect_to("/insufficient_balance") and return
        end 
      end

      create_cash_book(new_cashbook_path, rows, @payment_voucher)
      #check_for_cheque number duplicates
      rows = cash_book_rows(new_cashbook_path)
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
      create_cash_book(new_cashbook_path, rows, @payment_voucher, false) #remove duplicates
      
      `cp #{new_cashbook_path} #{file_path}`
      redirect_to("/update_cash_book_menu?voucher_id=#{params[:voucher_id]}") and return
    end
  end

  def insufficient_balance
    @payment_voucher = PaymentVoucher.find(session[:voucher_id]) rescue nil
    if @payment_voucher.blank?
      flash[:error] = "Something went wrong"
      redirect_to("/") and return
    end
    @cash_balance = session[:cash_balance]
    @page_header = "Insufficient balance for voucher #:  #{@payment_voucher.voucher_number}"
  end
  
  def cash_book_rows(file_path)
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
  
  def create_cash_book(new_cashbook_path, rows, payment_voucher, new_entry = true)
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

  def download_cash_book
    file_path = "#{Rails.root}/doc/cash_book.xls"
    if (File.file?(file_path))
      send_file "#{file_path}", :disposition => "attachment"
    else
      flash[:error] = "No cash book was found"
      redirect_to("#{request.referrer}") and return
    end
    
  end

  def upload_cash_book
    @page_header = "Upload cash book"

    if request.post?
      uploaded_io = params["input-file"]
      if uploaded_io.blank?
        flash[:error] = "Select file first"
        redirect_to("/upload_cash_book") and return
      end

      file_extension =  File.extname(uploaded_io.original_filename)
      if (file_extension != '.xls')
        flash[:error] = "Unsupported file format. Upload an excel file with .xls extension"
        redirect_to("/upload_cash_book") and return
      end
      
      new_name = "cash_book"
      new_file_name = new_name.to_s + file_extension.to_s
      File.open(Rails.root.join('doc' , new_file_name), 'wb') do |file|
        file.write(uploaded_io.read)
      end
      flash[:notice] = "Cash book has been uploaded successfully"
      redirect_to("/") and return
    end
    
  end
  
  def voucher_downloadable
    @payment_voucher = PaymentVoucher.find(params[:voucher_id])
    @workings = @payment_voucher.workings
    sub_total = @payment_voucher.voucher_amount.to_f
    @user_details = ""
    user = User.find(@payment_voucher.prepared_by) rescue nil
    unless user.blank?
      fname = user.first_name.capitalize.to_s rescue user.first_name
      lname = user.last_name.capitalize.to_s rescue user.last_name
      @user_details = (fname + " " + lname)
    end
    @workings.each do |payment_voucher_working|
      plus_minus = payment_voucher_working.workings.value
      workings_percent = payment_voucher_working.workings.percent
      calculated_value = ((workings_percent.to_f/100) * @payment_voucher.voucher_amount.to_f)
      payable_amount_string = "#{sub_total}#{plus_minus}#{calculated_value}"
      #raise payable_amount_string.inspect
      sub_total = eval(payable_amount_string)
      #raise sub_total.inspect
      #raise calculated_value.inspect
    end
    @payable_amount = sub_total
    @page_header = "Viewing payment voucher #:  #{@payment_voucher.voucher_number}"
    render :layout => false
  end
  
  def print_voucher
    voucher_id = params[:voucher_id]
    user_id = params[:user_id]
    voucher = PaymentVoucher.find(voucher_id)
    file_name = "voucher_#{voucher.payment_voucher_id}"
    t1 = Thread.new{
      Kernel.system "wkhtmltopdf --margin-top 0 --margin-bottom 0 -s A4 http://" +
        request.env["HTTP_HOST"] + "\"/voucher_downloadable?voucher_id=#{voucher_id}&user_id=#{user_id}" + "\" /tmp/#{file_name}" + ".pdf \n"
    }
    t1.join

    pdf_filename = "/tmp/#{file_name}.pdf"
    send_file(pdf_filename, :filename => "#{file_name}", :type => "application/pdf")
  end

end
