module SLAWatcher
  # This test will be executed every 15mins and will test, if all of the contracts, which have monitoring enabled, are going well
  # If not, for each contract only one event will be created and this event will be resend (every 1 hour) until resolved
  class ErrorTest < BaseTest
    EVENT_TYPE = 'ERROR_TEST'.freeze
    SEVERITY = Severity.HIGH

    def initialize
      super()
    end

    def start
      @@log.info "Starting the #{EVENT_TYPE} test"
      @new_events = []
      load_data
      @schedules.each do |s|
        executions = @last_five_executions[s.id]
        next if executions.nil?
        last_execution = executions[-1]
        second_last_execution = executions[-2]
        # Lets look on last execution and see if there is some problem on the way
        next unless last_execution.status == 'ERROR' || (last_execution.status == 'RUNNING' && !second_last_execution.nil? && second_last_execution.status == 'ERROR')
        # Last execution is Running or ERROR ... we need to go deeper in history to check if there is some reccuring problem
        last_ok_status_index = -1
        executions.each_with_index do |execution, i|
          last_ok_status_index = i if execution.status == 'FINISHED'
        end

        number_of_consequent_errors = executions.count - last_ok_status_index - 1
        pd_alert_limit = s.max_number_of_errors #TODO + 3 if execution matches filters
        next unless number_of_consequent_errors > pd_alert_limit
        # Create a PD error
        executions.each_with_index do |e, index|
          notification_already_sent = @notification_logs.has_key?(e.id.to_s)
          next unless index > last_ok_status_index && e.status == 'ERROR' && !notification_already_sent
          error_order = index - last_ok_status_index
          base_text = "The execution for this schedule has failed. This is #{error_order} error in row."
          error_text = e.error_text
          @new_events << CustomEvent.new(
            Key.new(e.id, EVENT_TYPE),
            SEVERITY,
            base_text,
            @now,
            nil,
            s.id,
            nil,
            error_text
          )
        end
      end
      @@log.info "The test #{EVENT_TYPE} has finished. Created #{@new_events.count} events"
      @new_events
    end

    def load_data
      @now = DateTime.now
      @schedules = Schedule.joins(:contract).where(project: {is_deleted: false, status: 'Live'}, contract: {is_deleted: false}, schedule: {is_deleted: false})
      @notification_logs = NotificationLog.where(notification_type: EVENT_TYPE, created_at: (@now - 9.day)..@now).group_by { |x| x.key }
      @last_five_executions = ExecutionLog.get_last_five_executions_per_schedule.group_by { |x| x.r_schedule }
    end
  end
end
