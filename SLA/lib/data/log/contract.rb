module SLAWatcher
  class Contract < ActiveRecord::Base
    self.table_name = 'contract'
    belongs_to :customer
    has_many :mutes

    scope :with_mutes, -> { includes(:mutes) }

    def all_mutes
      mutes
    end

    def muted?
      all_mutes.select { |m| m.active? }.any?
    end
  end
end