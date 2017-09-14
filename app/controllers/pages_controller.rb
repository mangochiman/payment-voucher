class PagesController < ApplicationController
  def home
    @page_header = "Dashboard"
  end

  def new_voucher_menu
    @page_header = "New payment voucher"
    if request.post?
      new_payment_voucher = PaymentVoucher.new_payment_voucher(params)
      if new_payment_voucher.save
        flash[:notice] = "New payment voucher was saved"
        redirect_to("/view_voucher_menu")
      else
        flash[:error] = "Failed to save the payment voucher"
        redirect_to("/new_voucher_menu")
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
    end
  end

  def new_user
    @page_header = "New user"
  end

  def remove_user
    @page_header = "Remove user"
  end

  def payments_report
    @page_header = "Payments Report"
  end
  
end
