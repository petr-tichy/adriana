module SLAWatcher
  class NotificationRemovalTask


    def initialize

    end

    def start()
      @schedules = Schedule.joins(:settings_server).joins(:project).joins(:contract).where(settings_server: {server_type: 'cloudconnect'}, schedule: {is_deleted: false },project: {is_deleted: false,status: 'Live'})
      @servers = SettingsServer.where({server_type: 'cloudconnect'})
      # Lets load the Contract specific resources
      @contracts = Contract.where("resource IS NOT NULL")

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
      #@resources.delete_if {|s| s["username"] == "ms+twcdigitalops@gooddata.com" }


      @@log.info "Resource loaded successfully"

      @resources.each do |resource|
        resource_schedules = @schedules.find_all {|s| s.settings_server_id == resource["server_id"]} if resource["type"] == "global"
        resource_schedules = @schedules.find_all {|s| s["contract_id"] == resource["contract_id"]} if resource["type"] == "contract"

        #pp resource_schedules

        settings_server = @servers.find{|s| s.id == resource["server_id"]}
        GoodData.connect(resource["username"],resource["password"],{:server => settings_server.server_url})
        pp settings_server.server_url
        resource_schedules.each do |s|
          begin
            # I will ignore pagination here, because default is good enought for me (last 100 executions)
            response = Helper.retryable do
              GoodData.get("/gdc/projects/#{s.r_project}/schedules/#{s.gooddata_schedule}")
            end

            reschedule = response["schedule"]["reschedule"]
            # pp reschedule
            #if (reschedule.nil?)
            #    response["schedule"].delete("nextExecutionTime")
            #    response["schedule"].delete("lastSuccessful")
            #    response["schedule"].delete("lastExecution")
            #    response["schedule"].delete("consecutiveFailedExecutionCount")
            #    response["schedule"].delete("ownerLogin")
            #    response["schedule"].delete("links")
            #    response["schedule"].delete("state")
            #    response["schedule"]["reschedule"] = 15
            #    res = GoodData.put("/gdc/projects/#{s.r_project}/schedules/#{s.gooddata_schedule}",response)
            #    @@log.info s.gooddata_schedule
            #end

            process_id = response["schedule"]["params"]["PROCESS_ID"]
            response =  GoodData.get("/gdc/projects/#{s.r_project}/dataload/processes/#{process_id}/notificationRules")
            items = response["notificationRules"]["items"]
            items.each do |item|
              if (item["notificationRule"]["email"].downcase == "cloudconnect@gooddata.pagerduty.com")
                self_link = item["notificationRule"]["links"]["self"]
                item["notificationRule"].delete("links")
                item["notificationRule"]["email"] = "ms+pagerduty@gooddata.com"
                res = GoodData.put(self_link,item)
                @@log.info self_link
              else
                @@log.info "Other notification, leaving as it is #{s.r_project}"
              end
            end



            #@@log.info "The Schedule #{s.gooddata_schedule} has been downloaded"
          #rescue => e
          #  @@log.warn "Problem in downloading schedule (#{s.gooddata_schedule}) for #{s.r_project} - #{e.message}"
          end
        end
        GoodData.disconnect
      end



    end

    def load_data()
      @user = AdminUsers.find_by_email("ms@gooddata.com")
    end



  end
end

