module SLAWatcher

  # This test will be executed every 15mins and will test, if all of the contracts, which have monitoring enabled, are going well
  # If not, for each contract only one event will be created and this event will be resend (every 1 hour) until resolved


  class ContractErrorTest < BaseTest


    def initialize(events)
      super(events)
      @EVENT_TYPE       =   "CONTRACT_ERROR_TEST"
      @SEVERITY         =   Severity.HIGH
    end

    def start()
      load_data
      @contracts.each do |contract|
        contract_executions = @last_executions.find_all{|e| e["contract_id"] == contract.id.to_s}
        contract_schedules = @schedules.find_all {|s| s.project.contract_id == contract.id}
        error_executions = contract_executions.find_all{|e| e.status == "ERROR"}

        number_of_error = error_executions.count
        number_of_schedules = contract_schedules.count
        if ((Float(number_of_error)/Float(number_of_schedules)) > (Float(contract.monitoring_treshhold)/100))
          puts "error"
        end

      end

    end

    def load_data()
      @last_executions = RunningExecutions.get_last_executions_with_contract
      @contracts = Contract.all
      @schedules = Schedule.includes(:project).where("project.contract_id IS NOT NULL and schedule.is_deleted = false")
    end

  end


end