class ErrorFilter < ActiveRecord::Base
  self.table_name = 'error_filter'
  self.primary_key = 'id'

  validates_presence_of :message, :admin_user_id

  belongs_to :admin_user

  def active?
    self.active
  end
end
