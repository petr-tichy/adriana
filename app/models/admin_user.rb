class AdminUser < ActiveRecord::Base
  role_based_authorizable
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :recoverable, :rememberable, :trackable, :validatable

  has_many :mutes
  has_many :error_filters

  def self.gd_technical_admin
    AdminUser.find_by_email('ms@gooddata.com')
  end
end
