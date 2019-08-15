class ChangeJobHistoryType < ActiveRecord::Migration
  def change
    change_column :job_history,:status,:string
  end



end
