class CreateJobHistory < ActiveRecord::Migration
  def change

    create_table "job_history" do |t|
      t.references :job, index: true
      t.datetime :started_at
      t.datetime :finished_at
      t.boolean :status
      t.text :log
      t.timestamps
    end

    remove_column :job, :started_at
    remove_column :job, :finished_at
    remove_column :job, :status
    remove_column :job, :log

  end

end
