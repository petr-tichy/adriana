class NotificationLog < ActiveRecord::Base
  self.table_name = 'notification_log'
  self.primary_key = 'id'
end
