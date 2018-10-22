module SLAWatcher
  class ErrorFilter < ActiveRecord::Base
    self.table_name = 'error_filter'

    scope :active, -> { where(active: true) }
    scope :inactive, -> { where(active: false) }

  end
end