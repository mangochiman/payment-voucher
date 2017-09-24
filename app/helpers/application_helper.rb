# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def available_users
    all_users = User.all
    return all_users
  end
end
