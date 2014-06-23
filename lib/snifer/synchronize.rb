require "gooddata"
require 'benchmark'

module SLAWatcher

  class Synchronize


    def load_data()


      @schedules_on_thread = 200
      @last_execution = Helper.value_to_datetime(Settings.load_last_splunk_synchronization.first.value)
      @now = DateTime.now
      # Lets load generic resources for servers
      @servers = SettingsServer.where("server_type = 'cloudconnect'")
      # Lets load the Contract specific resources
      @contracts = Contract.where("resource IS NOT NULL")
      # Here we will contact the password manager and download the passwords
      @schedules = Schedule.joins(:settings_server).joins(:contract).where("server_type = 'cloudconnect' and schedule.is_deleted = 'f'")

      @resources = []
      @servers.each do |s|
        @resources.push({
                            "uniq" => s.name,
                            "name" => s.default_account,
                            "type" => "global",
                            "server_id" => s.id

                        }
        )
      end

      @schedules.each do |s|
        @resources.push({
                            "uniq" => s["contract_id"],
                            "name" => s["contract_resource"],
                            "type" => "contract",
                            "contract_id" => s["contract_id"]
                        })
      end
      @resources.uniq!{|s| s["uniq"]}
      #@resources.delete_if{|s| s["name"].nil? or s["name"] == "" or !(s["name"] == "ManageServices-Gooddata|l2-cloudconn@gooddata.com")}
      @resources.delete_if{|s| s["name"].nil? or s["name"] == ""}
      #Load password from passman
      @@log.info "Loading resource from Password Manager"
      @resources.each do |resource|
        resource["username"] = resource["name"].split("|").last
        resource["password"] = PasswordManagerApi::Password.get_password_by_name(resource["name"].split("|").first,resource["name"].split("|").last)
      end
      @@log.info "Resource loaded successfully"
    end


    def work
        @execution_start = []
        @execution_end = []
        @thread_resources = []




        @resources.each do |resource|
          resource_schedules = @schedules.find_all {|s| s.settings_server_id == resource["server_id"]} if resource["type"] == "global"
          resource_schedules = @schedules.find_all {|s| s["contract_id"] == resource["contract_id"]} if resource["type"] == "contract"
          counter = 0
          elements = []
          resource_schedules.each do |e|
            elements << e
            counter += 1
            if (counter >= @schedules_on_thread)
              @thread_resources.push([elements,resource])
              elements = []
              counter = 0
            end
          end
          @thread_resources << [elements,resource] if elements.count > 0
        end
        i = 1

        puts "Starting threads!!!!"
        threads = @thread_resources.map do |e|
          Thread.new do
            do_stuff(e)
          end
        end

        threads.each {|t| t.join}

        starts = check_request_id(@execution_start,'STARTED')
        errors_finished = check_request_id(@execution_end,'FINISHED')

        # We need to use transaction, because of UPDATE on the end of the query
        ActiveRecord::Base.transaction do
          # Save the events to the database
          starts.each do |event|
            ExecutionLog.log_execution_api(event["schedule_id"],event["status"],"From Splunk synchronizer",event["time"],event["execution_id"])
          end

          errors_finished.each do |event|
            ExecutionLog.log_execution_api(event["schedule_id"],event["status"],"From Splunk synchronizer",event["time"],event["execution_id"])
          end

          #Save the last run date
          Settings.save_last_splunk_synchronization(@now)
        end
    end


    def do_stuff(settings_array)
      schedules = settings_array[0]
      resource = settings_array[1]
      execution_start = []
      execution_end = []

      puts "yeah I have started"
      settings_server = @servers.find{|s| s.id == resource["server_id"]}
      GoodData.connect(resource["username"],resource["password"],{:server => settings_server.server_url})
      #GoodData.logger = @@log
      #GoodData.logger.level = Logger::DEBUG
      schedules.each do |s|
        begin
          # I will ignore pagination here, because default is good enought for me (last 100 executions)
          response = Helper.retryable do
            GoodData.get("/gdc/projects/#{s.r_project}/schedules/#{s.gooddata_schedule}/executions")
          end
          response["executions"]["items"].each do |e|
            execution = Execution.new(e)
            if (execution.status == "RUNNING")
              if (execution.startTime > @last_execution - 24.hours)
                execution_start << {"execution_id" => execution.id, "event_time" => execution.startTime,"status" => "STARTED","schedule_id" => s.gooddata_schedule, "project_pid" => s.r_project }
              end
            elsif (execution.status == "OK" or execution.status == "ERROR")
              if (execution.startTime > @last_execution - 24.hours or execution.endTime > @last_execution - 24.hours )
                execution_start << {"execution_id" => execution.id, "event_time" => execution.startTime,"status" => "STARTED","schedule_id" => s.gooddata_schedule , "project_pid" => s.r_project }
                execution_end << {"execution_id" => execution.id, "event_time" => execution.endTime,"status" => execution.status == "OK" ? "FINISHED" : "ERROR","schedule_id" => s.gooddata_schedule , "project_pid" => s.r_project }
              end
            end
          end
        rescue => e
          @@log.warn "Problem in downloading schedule (#{s.gooddata_schedule}) for #{s.r_project} - #{e.message}"
        end
      end
      GoodData.disconnect
      #puts "Execution start:#{execution_start.count}"
      #puts "Execution end:#{execution_end.count}"
      @execution_start += execution_start
      @execution_end += execution_end
    end


    def check_request_id(values,type)
      #Fill temp_request table
      Request.delete_all()
      batch_size = 500
      batch = []
      values.each do |value|
        batch << Request.new(:request_id => value["execution_id"])
        if batch.size >= batch_size
          Request.import batch
          batch = []
        end
      end
      Request.import batch

      if (type == 'STARTED')
        requests = Request.check_request_id_started
      else
        requests = Request.check_request_id_finished
      end


      values.delete_if do |element|
        e = requests.find{|r| r.request_id == element["execution_id"]}
        if (e.nil?)
          true
        else
          false
        end
      end
      values
    end



  end
end