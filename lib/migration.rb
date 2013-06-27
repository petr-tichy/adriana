module SLAWatcher

  class Migration

    def initialize
      project_category_id = SLAWatcher::Settings.load_project_category_id.first.value
      task_category_id = SLAWatcher::Settings.load_schedule_category_id.first.value


      @projects_in_stage = SLAWatcher::StageProject.project_by_category(project_category_id)
      @projects_in_log = SLAWatcher::Project.select("*")

      @schedule_in_stage = SLAWatcher::StageTask.task_by_category(task_category_id)
      @schedule_in_log =  SLAWatcher::Schedule.select("*")

      @validity_check = []

    end


    def compare_stage_log_project
      @@log.info "Starting Stage > Log project migration"
      @projects_in_stage.each do |stage_project|

        p = @projects_in_log.find {|log_project| stage_project.de_project_pid == log_project.project_pid}
        stage_username = stage_project.email || stage_project.ms_person
        if (!p.nil?) then
            # Project is already in LOG database
          changeWatcher = ChangeWatcher.new(p.project_pid)
          changeWatcher.addComparer(Comparer.new(p.status,stage_project.de_operational_status,"status"))
          changeWatcher.addComparer(Comparer.new(p.name,stage_project.name,"name"))
          changeWatcher.addComparer(Comparer.new(p.ms_person,stage_username,"ms_person"))
          changeWatcher.addComparer(Comparer.new(p.is_deleted,"false","is_deleted"))
          changeWatcher.addComparer(Comparer.new(p.sla_enabled,(stage_project.sla_enabled == "Enabled" ? true : false),"sla_enabled"))
          changeWatcher.addComparer(Comparer.new(p.sla_type,stage_project.sla_type,"sla_type"))
          changeWatcher.addComparer(Comparer.new(p.sla_value,stage_project.sla_value,"sla_value"))

          if (!changeWatcher.same?)

            ActiveRecord::Base.transaction do
              changeWatcher.log_changes(@@log,"project",p.name,p.project_pid)
              changeWatcher.save_history_to_db("project_history")
              changeWatcher.different_values.each do |value|
                p[value.key] = value.secondValue
              end
              p.save
            end

          end
        else
          # Project is not in LOG database, we need to create him
          Project.create(:project_pid => stage_project.de_project_pid, :status => stage_project.de_operational_status, :name => stage_project.name,:ms_person => stage_username,:sla_enabled => (stage_project.sla_enabled == "Enabled" ? true : false),:sla_type => stage_project.sla_type, :sla_value => stage_project.sla_value,:created_at => DateTime.now)
          @@log.info "The project #{stage_project.name} (#{stage_project.de_project_pid}) has been created"
          @@log.info "Status - new value: #{stage_project.de_operational_status}"
          @@log.info "Name - new value: #{stage_project.name}"
          @@log.info "Sla Enabled - new value: #{(stage_project.sla_enabled == "Enabled" ? true : false)}"
          @@log.info "Sla Type - new value: #{stage_project.sla_type}"
          @@log.info "Sla Value - new value: #{stage_project.sla_value}"
          @@log.info "-----------------------------------------------------------------"

        end
      end

      @projects_in_log.find_all{|p| p.is_deleted == false}.each do |log_project|
        # The project is in Log database, but it was not found in stage (most likely due to delete)
        p =  @projects_in_stage.find {|stage_project| log_project.project_pid == stage_project.de_project_pid}
        if (p.nil?)
          changeWatcher = ChangeWatcher.new(log_project.project_pid)
          changeWatcher.addComparer(Comparer.new("false","true","is_deleted"))

          ActiveRecord::Base.transaction do
            changeWatcher.log_changes(@@log,"project",log_project.name,log_project.project_pid)
            changeWatcher.save_history_to_db("project_history")
            changeWatcher.different_values.each do |value|
              log_project[value.key] = value.secondValue
            end
            log_project.save
          end
        end
      end
      @@log.info "Ending Stage > Log project migration"
    end


    def compare_stage_log_schedule
      @@log.info "Starting Stage > Log schedule migration"
      @schedule_in_stage.each do |stage_schedule|
          s = @schedule_in_log.find {|log_schedule| log_schedule.r_project == stage_schedule.project_pid and log_schedule.graph_name == stage_schedule.graph.downcase and log_schedule.mode == Helper.downcase(stage_schedule.mode)}
          valid = true
          valid_list = Helper.validate_cron(stage_schedule.cron)
          valid_list.each do |list|
            if (list[:valid] == false)
              create_validity_message(stage_schedule.project_pid,stage_schedule.graph.downcase,stage_schedule.mode.downcase,nil,"Cron expresion: #{stage_schedule.cron} is not valid")
              valid = false
            end
          end

          if (stage_schedule.project_pid == '')
            create_validity_message(stage_schedule.project_pid,stage_schedule.graph.downcase,stage_schedule.mode.downcase,nil,"Looks like projects and task are not synchronized in stage")
            valid = false
          end


          if (valid)
            if (!s.nil?)
              # Schedule is already in LOG database

              changeWatcher = ChangeWatcher.new(s.id)
              changeWatcher.addComparer(Comparer.new(s.cron,stage_schedule.cron.downcase,"cron"))
              changeWatcher.addComparer(Comparer.new(s.server,stage_schedule.server.downcase,"server"))
              changeWatcher.addComparer(Comparer.new(s.is_deleted,"false","is_deleted"))
              changeWatcher.addComparer(Comparer.new(s.main,(stage_schedule.main == "Yes" ? true : false),"main"))

              if (!changeWatcher.same?)

                ActiveRecord::Base.transaction do
                  changeWatcher.log_changes(@@log,"schedule",s.graph_name.downcase,s.r_project)
                  changeWatcher.save_history_to_db("schedule_history")
                  changeWatcher.different_values.each do |value|
                    s[value.key] = value.secondValue
                  end
                  s.save
                end
              end
            else
              # Schedule is is not in LOG database, we need to create it
              Schedule.create(:r_project => stage_schedule.project_pid, :mode => Helper.downcase(stage_schedule.mode), :graph_name => stage_schedule.graph.downcase, :server => stage_schedule.server,:cron => stage_schedule.cron,:main => (stage_schedule.main == "Yes" ? true : false),:created_at => DateTime.now)
              @@log.info "The schedule for project #{stage_schedule.project_pid} (Graph: #{stage_schedule.graph.downcase}, Mode: #{Helper.downcase(stage_schedule.mode)}) has been created"
              @@log.info "Server - new value: #{stage_schedule.server}"
              @@log.info "Cron - new value: #{stage_schedule.cron}"
              @@log.info "Main - new value: #{stage_schedule.main == "Yes" ? true : false}"
              @@log.info "-----------------------------------------------------------------"
            end
          end
      end

      @schedule_in_log.find_all{|s| s.is_deleted == false}.each do |log_schedule|
        # The schedule is in Log database, but it was not found in stage (most likely due to delete)

        s =  @schedule_in_stage.find {|stage_schedule| log_schedule.r_project == stage_schedule.project_pid and log_schedule.graph_name == stage_schedule.graph.downcase and log_schedule.mode == Helper.downcase(stage_schedule.mode)}
        if (s.nil?)


          changeWatcher = ChangeWatcher.new(log_schedule.id)
          changeWatcher.addComparer(Comparer.new(log_schedule.is_deleted,"true","is_deleted"))

          ActiveRecord::Base.transaction do
            changeWatcher.log_changes(@@log,"schedule",log_schedule.graph_name,log_schedule.r_project)
            changeWatcher.save_history_to_db("schedule_history")
            changeWatcher.different_values.each do |value|
              log_schedule[value.key] = value.secondValue
            end
            log_schedule.save
          end
        end
      end
      @@log.info "Ending Stage > Log schedule migration"

      ## TO DO - validation message sending
      @validity_check.each do |e|
        @@log.warn "---------- Validation Message ----------"
        @@log.warn "Project - #{e.key} has following validation problems:"
        e.value.each do |v|
          @@log.warn "Graph name - #{v[:graph_name]} mode - #{v[:mode]}"
          @@log.warn v[:message]
        end
        @@log.warn "---------- Validation Message ----------"
      end





    end



    def create_validity_message(project_pid,graph_name,mode,value,validity_message)
        record = @validity_check.find {|key,value| key == project_pid}
        if (record.nil?)
          @validity_check.push({ project_pid => [{:graph_name => graph_name,:mode=>mode,:message => validity_message}]})
        else
          record.value.push({:graph_name => graph_name,:mode=>mode,:message => validity_message})
        end
    end




  end
end