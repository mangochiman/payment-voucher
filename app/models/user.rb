require 'digest/sha1'
require 'digest/sha2'
require 'rest_client'
class User < ActiveRecord::Base
  set_table_name :users
  set_primary_key :user_id

  has_many :user_roles, :dependent => :destroy
  has_many :api_keys, :foreign_key => :user_id, :dependent => :destroy

  validates_presence_of :first_name, :message => ' can not be blank'
  validates_presence_of :last_name, :message => ' can not be blank'
  validates_presence_of :username, :message => ' can not be blank'
  validates_presence_of :phone_number, :message => ' can not be blank'
  validates_presence_of :email, :message => ' can not be blank'
  validates_uniqueness_of :username, :message => ' already taken'
  validates_uniqueness_of :email, :message => ' already taken'
  validates_uniqueness_of :phone_number, :phone_number => ' already taken'

  cattr_accessor :current_user
  default_scope :conditions => "#{self.table_name}.voided = 0"
  
  def try_to_login
    User.authenticate(self.username,self.password)
  end

  def self.authenticate(login, password)
    u = find :first, :conditions => {:username => login}
    u && u.authenticated?(password) ? u : nil
  end

  def authenticated?(plain)
    encrypt(plain, salt) == password || Digest::SHA1.hexdigest("#{plain}#{salt}") == password || Digest::SHA512.hexdigest("#{plain}#{salt}") == password
  end

  def encrypt(plain, salt)
    encoding = ""
    digest = Digest::SHA1.digest("#{plain}#{salt}")
    (0..digest.size-1).each{|i| encoding << digest[i].to_s(16) }
    encoding
  end

  def set_password
    self.salt = User.random_string(10) if !self.salt?
    self.password = User.encrypt(self.password,self.salt)
  end

  def self.random_string(len)
    chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
    newpass = ""
    1.upto(len) { |i| newpass << chars[rand(chars.size-1)] }
    return newpass
  end

  def self.encrypt(password,salt)
    Digest::SHA1.hexdigest(password+salt)
  end


  def self.new_user(params)
    salt = self.random_string(10)
    user = User.new
    user.first_name = params[:first_name]
    user.last_name = params[:last_name]
    user.email = params[:email]
    user.phone_number = params[:phone_number]
    user.password = self.encrypt(params[:password], salt)
    user.salt = salt
    user.username = params[:username]
    return user
  end

  def self.update_user(user, params)
    user.first_name = params[:first_name]
    user.last_name = params[:last_name]
    user.email = params[:email]
    user.phone_number = params[:phone_number]
    user.username = params[:username]
    user.secret_question = params[:secret_question]
    user.secret_answer = params[:secret_answer]
    return user
  end

  def void_user(params)
    user = self
    user.voided = 1
    user.voided_by = params[:voided_by]
    user.date_voided = Date.today
    return user
  end

  def self.roles
    roles = [
      ["Admin", 'Admin'],
      ['Accountant', 'Accountant']
    ]
    return roles
  end

  def role
    user_role = self.user_roles.last
    user_role = user_role.role unless user_role.blank?
    return user_role
  end

  def self.per_page
    per_page = 10
    return per_page
  end
  
end

