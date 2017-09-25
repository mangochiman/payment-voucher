# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details
  skip_before_filter :verify_authenticity_token  
  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password

  before_filter :authenticate_user
  filter_parameter_logging :password

  def authenticate_user
    user = User.find(session[:user].user_id) rescue nil
    unless user.blank?
      session[:user] = user
      return true
    end
    access_denied
    return false
  end

  def access_denied
    redirect_to ("/login") and return
  end

  def lock_screen_when_activated
    user = User.find(session[:user].user_id) rescue nil
    if user
      return true if session[:screen_locked].blank?
      redirect_to ("/lock_screen") and return
      return true
    end
  end

  def rescue_action(exception)
    @message = exception.message
    @backtrace = exception.backtrace.join("\n") unless exception.nil?
    logger.info @message
    logger.info @backtrace
    render :file => "#{RAILS_ROOT}/app/views/errors/404.rhtml", :layout=> false, :status => 404
  end #if RAILS_ENV == 'production'
end
