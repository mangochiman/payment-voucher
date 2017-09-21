require 'spreadsheet'
require 'writeexcel'
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
    @payment_vouchers = PaymentVoucher.find(:all, :order => "payment_voucher_id DESC")
  end

  def edit_this_voucher
    @payment_voucher = PaymentVoucher.find(params[:voucher_id])
    @page_header = "Editing payment voucher #:  #{@payment_voucher.voucher_number}"

    if request.post?
      edit_payment_voucher = PaymentVoucher.edit_payment_voucher(params)
      if edit_payment_voucher.save
        flash[:notice] = "Payment voucher was updated"
        redirect_to("/edit_voucher_menu")
      else
        flash[:error] = "Failed to update the voucher"
        redirect_to("/edit_this_voucher?voucher_id=#{params[:voucher_id]}")
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
    @payment_vouchers = PaymentVoucher.find(:all, :order => "payment_voucher_id DESC")
  end

  def void_voucher_menu
    @page_header = "Void payment voucher"
    @payment_vouchers = PaymentVoucher.find(:all, :order => "payment_voucher_id DESC")
    if request.post?
      void_voucher = PaymentVoucher.void_voucher(params[:voucher_id])
      if void_voucher.save
        flash[:notice] = "Voucher #: #{void_voucher.voucher_number} has been voided"
      else
        flash[:error] = "Failed to void the selected voucher"
      end
      redirect_to("/void_voucher_menu")
    end
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
    @users = User.all
  end

  def remove_user
    @page_header = "Remove user"
    @users = User.all
    if request.post?
      user = User.find(params[:user_id])
      user.void_user
      if user.save
        flash[:notice] = "#{user.username} has been voided"
      else
        flash[:error] = "Failed to void the selected user"
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
        flash[:error] = "Failed to save the workings"
        redirect_to("/new_workings")
      end
    end
  end

  def edit_workings
    @page_header = "Edit Workings"
    @workings = Workings.find(:all)
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
        flash[:error] = "Failed to update the workings"
        redirect_to("/edit_this_workings?workings_id=#{params[:workings_id]}")
      end
    end

  end

  def view_workings
    @page_header = "View Workings"
    @workings = Workings.find(:all)
  end

  def void_workings
    @page_header = "Void Workings"
    @workings = Workings.find(:all)

    if request.post?
      void_workings = Workings.void_workings(params[:workings_id])
      if void_workings.save
        flash[:notice] = "Workings : #{void_workings.name} has been voided"
      else
        flash[:error] = "Failed to void the selected voucher"
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
    @my_vouchers = PaymentVoucher.my_vouchers(session[:user])
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
    if request.post?
      #update cashbook here
      file_path = "#{Rails.root}/doc/cash_book.xls"
      new_cashbook_path = "#{Rails.root}/doc/cash_book2.xls"
      cash_book = Spreadsheet.open file_path
      cash_book_sheet = cash_book.worksheet 0

      total_rows = cash_book_sheet.count
      rows = []

      0.upto(total_rows - 1) do |i|
        cell_0 = cash_book_sheet.rows[i][0] 
        cell_1 = cash_book_sheet.rows[i][1]
        cell_2 = cash_book_sheet.rows[i][2]
        cell_3 = cash_book_sheet.rows[i][3]
        cell_4 = cash_book_sheet.rows[i][4]
        if cash_book_sheet.rows[i][5].class.name.match(/Spreadsheet::Formula/i)
          cell_5 = (cash_book_sheet.rows[i][5]).value
        else
          cell_5 = cash_book_sheet.rows[i][5]
        end
        rows << [cell_0, cell_1, cell_2, cell_3, cell_4, cell_5]
      end

      workbook = WriteExcel.new(new_cashbook_path)

      # Add worksheet(s)
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
        cell_0 = row[0]
        cell_1 = row[1]
        cell_2 = row[2]
        cell_3 = row[3]
        cell_4 = row[4]
        cell_5 = row[5]
        
        if (row_pos == 0)
          worksheet.write(row_pos, 0, cell_0, bold_format)
          worksheet.write(row_pos, 1, cell_1, bold_format)
          worksheet.write(row_pos, 2, cell_2, bold_format)
          worksheet.write(row_pos, 3, cell_3, bold_format)
          worksheet.write(row_pos, 4, cell_4, bold_format)
          worksheet.write(row_pos, 5, cell_5, bold_format)
        else
          worksheet.write(row_pos, 0, cell_0)
          worksheet.write(row_pos, 1, cell_1)
          worksheet.write(row_pos, 2, cell_2)
          worksheet.write(row_pos, 3, cell_3)
          worksheet.write(row_pos, 4, cell_4, number_red_format)
          
          if (row_pos == 2)
            worksheet.write(row_pos, 5, cell_5, number_format)
          else
            formulae = "=F#{row_pos}+E#{row_pos + 1}"
            if cell_4.blank?
              worksheet.write(row_pos, 5, cell_5)
            else
              worksheet.write_formula(row_pos, 5,  formulae, number_red_format_condition)
            end
            
          end
          
        end

        row_pos = row_pos + 1
      end

      #voucher_number = @payment_voucher.voucher_number
      cheque_number = @payment_voucher.cheque_number
      voucher_date = @payment_voucher.voucher_date.to_date.strftime("%d.%m.%Y")
      voucher_amount = @payment_voucher.voucher_amount
      expenditure_details = @payment_voucher.expenditure_details
      #account_name = @payment_voucher.account_name
      #donor_code = @payment_voucher.donor_code
      payee_details = @payment_voucher.payee

      new_row_pos = row_pos
      formulae = "=F#{new_row_pos}+E#{new_row_pos + 1}"
      worksheet.write(new_row_pos, 0, voucher_date)
      worksheet.write(new_row_pos, 1, cheque_number)
      worksheet.write(new_row_pos, 2, payee_details)
      worksheet.write(new_row_pos, 3, expenditure_details)
      worksheet.write(new_row_pos, 4, -voucher_amount.to_i, number_red_format)
      worksheet.write_formula(new_row_pos, 5,  formulae, number_red_format_condition)
      # write to file
      workbook.close
      `cp #{new_cashbook_path} #{file_path}`
      redirect_to("/update_cash_book_menu?voucher_id=#{params[:voucher_id]}") and return
    end
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
  end
  
  def voucher_downloadable
    @payment_voucher = PaymentVoucher.find(params[:voucher_id])
    @workings = @payment_voucher.workings
    sub_total = @payment_voucher.voucher_amount.to_f
    user = User.find(params[:user_id])
    @user = (user.first_name + " " + user.last_name) rescue nil
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
