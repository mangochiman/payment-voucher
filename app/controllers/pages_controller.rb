class PagesController < ApplicationController
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

  def voucher_downloadable
    @payment_voucher = PaymentVoucher.find(params[:voucher_id])
    render :layout => false
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
        redirect_to("/sign_up") and return
      end
      user = User.new_user(params)

      if user.save
        UserRole.create_user_role(user, params)

        flash[:notice] = "You have created your account. You may now login. Your API key is <br />"
        redirect_to("/new_user") and return
      else
        flash[:error] = user.errors.full_messages.join('<br />')
        redirect_to("/new_user") and return
      end
    end
  end


  def remove_user
    @page_header = "Remove user"
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
  
end