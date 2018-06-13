class NotificationLog < ActiveRecord::Base
  self.table_name = 'notification_log'

  def url
    "nic"
  end
end
