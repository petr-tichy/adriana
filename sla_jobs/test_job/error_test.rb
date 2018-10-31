module TestJob
  # (Runs every 15 mins)
  # This test checks, that all contracts, which have monitoring enabled, are going well
  # If not, for each contract, only one event will be created into PD and this event will be resent (every 1 hour) until resolved
  class ErrorTest
    EVENT_TYPE = 'ERROR_TEST'.freeze
    SEVERITY = Severity.HIGH

    def load_data
      @now = DateTime.now
      @schedules = Schedule.joins(:contract).where(project: {is_deleted: false, status: 'Live'}, contract: {is_deleted: false}, schedule: {is_deleted: false})
      @notification_logs = NotificationLog.where(notification_type: EVENT_TYPE, created_at: (@now - 9.day)..@now).group_by(&:key)
      @last_ten_executions = ExecutionLog.get_last_n_executions_per_schedule(10).group_by(&:r_schedule)
    end

    def start
      $log.info "Starting the #{EVENT_TYPE} test"
      @new_events = []
      load_data
      @schedules.each do |schedule|
        executions = @last_ten_executions[schedule.id]
        next if executions.nil?
        last_execution = executions[-1]
        second_last_execution = executions[-2]
        # Lets look on last execution and see if there is some problem on the way
        last_error = (last_execution.status == 'ERROR')
        second_last_error = (last_execution.status == 'RUNNING' && second_last_execution && second_last_execution.status == 'ERROR')
        next unless last_error || second_last_error
        # Last execution is Running or ERROR ... we need to go deeper in history to check if there is some recurring problem
        last_ok_status_index = last_ok_status_index(executions)

        number_of_consequent_errors = executions.count - last_ok_status_index - 1
        pd_alert_limit = schedule.max_number_of_errors || 0
        # Let it fail 3 more times before sending the alert, if there are any error filters matching
        pd_alert_limit += 3 if [last_execution, second_last_execution].compact.any?(&:matches_error_filters)
        next unless number_of_consequent_errors > pd_alert_limit

        # Create a PD event
        executions.each_with_index do |execution, index|
          next unless execution.status == 'ERROR' && index > last_ok_status_index
          error_order = index - last_ok_status_index
          create_event_for_execution(execution, schedule.id, error_order)
        end
      end
      $log.info "The test #{EVENT_TYPE} has finished. Created #{@new_events.count} events."
      @new_events
    end

    def create_event_for_execution(execution, schedule_id, error_order)
      return if @notification_logs.has_key?(execution.id.to_s) # Notification was already sent for the execution
      base_text = "The execution for this schedule has failed. This is the #{error_order}. error in row."
      @new_events << CustomEvent.new(
        Key.new(execution.id, EVENT_TYPE),
        SEVERITY,
        base_text,
        @now,
        nil,
        schedule_id,
        nil,
        execution.error_text
      )
    end

    # Finds the last execution index with FINISHED status, otherwise -1
    def last_ok_status_index(executions)
      executions.rindex { |e| e.status == 'FINISHED' } || -1
    end
  end
end
