class UserRole < ActiveRecord::Base
  set_table_name :user_roles
  set_primary_key :user_role_id

  def self.create_user_role(user, params)
    user_role = UserRole.new
    user_role.user_id = user.user_id
    user_role.role = params[:role]
    user_role.save
  end

end
