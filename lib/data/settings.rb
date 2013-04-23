module SLAWatcher
  class Settings < ActiveRecord::Base
    self.table_name = 'log2.settings'

    def self.load_last_splunk_synchronization
      where("key = 'last_splunk_synchronization'")
    end

    def self.save_last_splunk_synchronization(time)
      record = where("key = 'last_splunk_synchronization'")
      record.first.value = Helper.datetime_to_value(time)
      record.first.save
    end

  end
end