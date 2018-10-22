class NewJobFieldIsDisabled < ActiveRecord::Migration
  def change
    add_column :job,:is_disabled,:boolean, :default => false
  end

end
