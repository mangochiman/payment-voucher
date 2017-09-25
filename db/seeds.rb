# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#   
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Major.create(:name => 'Daley', :city => cities.first)

def default_user
  params = {}
  params[:password] = "jphiri"
  params[:first_name] = "James"
  params[:last_name] = "Phiri"
  params[:email] = "jamesphiri@gmail.com"
  params[:phone_number] = "099900001"
  params[:username] = "jphiri"
  params[:role] = "Admin"
  user = User.new_user(params).save
  UserRole.create_user_role(user, params)
end

default_user