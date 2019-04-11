require_relative 'splunk_client'
require 'benchmark'

module SplunkSynchronizationJob
  class SplunkDownloader
    ONE_QUERY_LIMIT = 300

    attr_accessor :errors_to_match

    def initialize(username, password, hostname)
      @splunk = SplunkClient.new(username, password, hostname)
    end

    def execute_query(query)
      # Create the Search
      search = @splunk.search(query)
      #$log.info("Splunk query: #{query[0..256]}...")
      sleep(1)
      $log.info 'Waiting for Splunk results to be ready'
      search.poll_for_results
      search
    end

    # For an event, try to find and parse the appropriate error message
    # The message format is dependent on what type of brick was run
    def find_error_log(parsed_event, from)
      return nil unless parsed_event.respond_to?('type') && parsed_event.respond_to?('status') && parsed_event.status == 'ERROR'
      log_query = case parsed_event.type
                    when 'RUBY'
                      error_query_ruby parsed_event, from
                    when 'GRAPH'
                      error_query_clover parsed_event, from
                    else
                      if parsed_event.respond_to?('clover_graph') && parsed_event.clover_graph == 'DATALOAD'
                        error_query_dataload parsed_event, from
                      end
                  end
      return nil unless log_query
      log_results = execute_query(log_query).parsed_results.map { |r| r.respond_to?('log') ? r.log : nil }.compact
      return nil unless log_results&.any?
      # Take all log results and select the longest one - that is probably where the error message from execution log is located
      longest = log_results.max_by(&:length)
      longest.sub(/(Parsing error).*/mi, "\\1...")
    end

    def load_runs(from, to, projects)
      project_strings = prepare_projects_query(projects)

      values = []
      project_strings.each do |temp|
        query = last_runs_query.sub('%PIDS%', temp.join(' OR '))
        with_time_range(from, to) do |start_time, end_time|
          query = query.sub('%START_TIME%', start_time.strftime(time_format)).sub('%END_TIME%', end_time.strftime(time_format))
          result = nil
          $log.info "Running main Splunk query from #{start_time.strftime(time_format)} to #{end_time.strftime(time_format)}, #{(temp * ', ')[0..256]}..."
          $log.info("Duration: #{Benchmark.realtime do
            result = execute_query(query)
          end} s")
          $log.info 'Running related Splunk queries and parsing the events'
          $log.info("Duration: #{Benchmark.realtime do
            result&.parsed_results&.each do |p|
              error_text = find_error_log(p, start_time)
              matches_error_filters = matches_error_filters?(p, start_time)
              values.push(execution_hash(p, start_time, error_text, matches_error_filters))
              values.push(execution_hash(p, start_time, '', false))
            end
          end} s")
        end
      end
      output = nil
      $log.info 'Query sorting'
      $log.info("Duration: #{Benchmark.realtime do
        output = values.sort_by { |a| a[:time] }
      end} s")
      output
    end

    def prepare_projects_query(projects)
      project_strings = []
      $log.info 'Query initialization'
      0.step(projects.length - 1, ONE_QUERY_LIMIT) do |i|
        project_strings.push(projects[i, ONE_QUERY_LIMIT].map { |p| "project_id=#{p.project_pid}" })
      end
      project_strings
    end

    # Splits datetime interval [from, to] to smaller chunks
    # Helpful in case of Splunk outages, when we need to download longer periods than 8h without timing out
    def with_time_range(from, to, &block)
      duration = to - from
      if duration > 8.hours
        ranges = (from.to_i..to.to_i).step(8.hours.to_i).to_a.map { |x| Time.at(x) }
        ranges << to
        ranges.zip(ranges.rotate)[0...-1].each do |start_time, end_time|
          block.call(start_time, end_time)
        end
      else
        block.call(from, to)
      end
    end

    # Check if Splunk returns any results for queries containing special filtering errors
    def matches_error_filters?(parsed_event, from)
      return false unless parsed_event.respond_to?('status') && parsed_event.status == 'ERROR'
      errors_to_match = self.errors_to_match
      return false if errors_to_match.nil? || errors_to_match.empty?
      query = error_filter_query(parsed_event, from, errors_to_match)
      results = execute_query(query).parsed_results
      return false unless results.respond_to?(:first) && results.first.respond_to?(:total)
      total = results.first.total
      Integer(total).positive? rescue false
    end

    def execution_hash(search_result, from, error_text = nil, matches_error_filters = nil)
      {
        :project_pid => search_result.project_id,
        :schedule_id => search_result.schedule_id,
        :request_id => search_result.request_id,
        :clover_graph => search_result.respond_to?('clover_graph') ? Helper.extract_graph_name(search_result.clover_graph) : nil,
        :mode => search_result.respond_to?('mode') ? Helper.extract_mode(search_result.mode) : nil,
        :status => search_result.status,
        :time => DateTime.strptime(search_result._time, '%Y-%m-%dT%H:%M:%S.%L%z'),
        :error_text => error_text,
        :matches_error_filters => matches_error_filters
      }
    end

    private

    def time_format
      '%m/%d/%Y:%H:%M:%S'
    end

    def last_runs_query
      <<-EOS
        earliest=%START_TIME% latest=%END_TIME% source=/mnt/log/gdc-java sourcetype=log4j eventtype=MSF
        (component=workers.data-loader com.gooddata.msf.util.ScheduleExecutionUpdater) OR (action=process_run schedule_id="*")
        (%PIDS%)
        | rex "(clover_graph|executable)=(?<clover_graph>[^=]+) [^=]+=" | eval clover_graph=if(component=="workers.data-loader", "DATALOAD", clover_graph)
        | rex "Updated execution: /gdc/projects/[^/ ]+/schedules/(?<schedule_id>[^/ ]+)/executions/"
        | search schedule_id="*"
        | rex field=request_id "^(?<request_id>[^ ]*)"
        | eval status=coalesce(case(status=="RUNNING", "STARTED", status=="OK", "FINISHED"), status)
        | table project_id schedule_id request_id clover_graph mode status _time type
      EOS
    end

    def error_query_ruby(parsed_event, from)
      <<-EOS
        earliest=#{from.strftime(time_format)} #{parsed_event.request_id} "Error executing script!" "component=execmgr.executor-wrapper"
        | rex field=_raw "(?<log>Error executing script!(.*\\n?)*)"
        | table log
      EOS
    end

    def error_query_clover(parsed_event, from)
      <<-EOS
        earliest=#{from.strftime(time_format)} #{parsed_event.request_id} "component=workers.clover-executor" "com.gooddata.clover.exception.CloverException"
        | rex field=_raw "(?<log>com.gooddata.clover.exception.CloverException:(.*\\n?)*)"
        | table log
      EOS
    end

    def error_query_dataload(parsed_event, from)
      <<-EOS
        earliest=#{from.strftime(time_format)} #{parsed_event.request_id} "component=workers.data-loader"
        | eval log=_raw
        | table log
      EOS
    end

    def error_filter_query(parsed_event, from, errors_to_match)
      str = <<-EOS
        earliest=#{from.strftime(time_format)} request_id=#{parsed_event.request_id}
        (%ERRS%) | stats count as total
      EOS
      str.sub('%ERRS%', "\"#{errors_to_match.join('" OR "')}\"")
    end
  end
end