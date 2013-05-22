module SLAWatcher
  class StageTask < ActiveRecord::Base
    self.table_name = 'stage.task'


    def self.task_by_category(category)
      select('task.de_graph as graph,task.de_mode as mode,task.de_server as server,task.de_cron as cron,project.de_project_pid as project_pid').joins('LEFT OUTER JOIN stage.project project ON project.id = task.projectid').where("task.categoryid = ?",category)
    end



  end
end