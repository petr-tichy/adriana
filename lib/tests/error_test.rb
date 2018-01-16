module SLAWatcher

  # This test will be executed every 15mins and will test, if all of the contracts, which have monitoring enabled, are going well
  # If not, for each contract only one event will be created and this event will be resend (every 1 hour) until resolved


  class ErrorTest < BaseTest


    def initialize
      super()
      @EVENT_TYPE = 'ERROR_TEST'
      @SEVERITY = Severity.HIGH
    end

    def start
      @@log.info "Starting the #{@EVENT_TYPE} test"
      @new_events = []
      load_data
      @schedules.each do |s|
        executions = @last_five_executions[s.id]
        next if executions.nil?
        last_execution = executions.last
        # Lets look on last execution and see if there is some problem on the way
        if last_execution.status == 'ERROR' or (last_execution.status == 'RUNNING' and !executions[-2].nil? and executions[-2].status == 'ERROR')
          # Last execution is Running or ERROR ... we need to go deeper in history to check if there is some reccuring problem
          last_ok_status_index = -1
          executions.each_with_index do |execution, i|
            last_ok_status_index = i if execution.status == 'FINISHED'
          end
          # Lets count the number of consequent errors
          if executions.count - last_ok_status_index - 1 > s.max_number_of_errors
            # eah we need to create PD error
            executions.each_with_index do |e, index|
              if index > last_ok_status_index and e.status == 'ERROR'
                unless @notification_logs.has_key? e.id.to_s
                  @new_events << CustomEvent.new(
                      Key.new(e.id, @EVENT_TYPE), @SEVERITY,
                      "The execution for this schedule has failed. This is #{index - last_ok_status_index} error in row.",
                      @now, nil, s.id)
                end
              end
            end
          end
        end
      end
      @@log.info "The test #{@EVENT_TYPE} has finished. Created #{@new_events.count} events"
      @new_events
    end

    def load_data
      @now = DateTime.now
      @schedules = Schedule.joins(:project).joins(:contract).where(project: {is_deleted: false, status: 'Live'}, schedule: {is_deleted: false})
      @notification_logs = NotificationLog.where(notification_type: @EVENT_TYPE, created_at: (@now - 9.day)..@now).group_by { |x| x.key }
      @last_five_executions = ExecutionLog.get_last_five_executions_per_schedule.group_by { |x| x.r_schedule }
    end

  end

end
