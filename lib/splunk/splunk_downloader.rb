require 'splunk-client'
require 'nokogiri'
require 'benchmark'

module SLAWatcher
  class SplunkDownloader
    ONE_QUERY_LIMIT = 300

    attr_accessor :errors_to_match

    def initialize(username, hostname)
      password = PasswordManagerApi::Password.get_password_by_name(username.split('|').first, username.split('|').last)
      @splunk = SplunkClient.new(username.split('|').last, password, hostname)
    end

    def execute_query(query)
      # Create the Search
      search = @splunk.search(query)
      @@log.info("splunk query: #{query}")
      sleep(1)
      search.wait # Blocks until the search returns
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
      log_results = execute_query(log_query).parsedResults.map { |r| r.respond_to?('log') ? r.log : nil }.compact
      if log_results && log_results.any?
        longest = log_results.max_by(&:length)
        longest.sub(/(Parsing error).*/mi, "\\1...")
      else
        nil
      end
    end

    def load_runs(from, to, projects)
      project_strings = []
      @@log.info 'Query initialization' + Benchmark.measure do
        0.step(projects.length - 1, ONE_QUERY_LIMIT) do |i|
          project_strings.push(projects[i, ONE_QUERY_LIMIT].map { |p| "project_id=#{p.project_pid}"} )
        end
      end.to_s

      values = []
      project_strings.each do |temp|
        query = last_runs_query.sub('%PIDS%', temp.join(' OR '))
        query = query.sub('%START_TIME%', from.strftime(time_format))
        query = query.sub('%END_TIME%', to.strftime(time_format))
        result = nil
        @@log.info 'Query execution' + Benchmark.measure do
          result = execute_query(query)
        end.to_s
        @@log.info 'Query parsing' + Benchmark.measure do
          result.parsedResults.each do |p|
            values.push(execution_hash(p, from))
          end
        end.to_s
      end
      output = nil
      @@log.info 'Query sorting' + Benchmark.measure do
        output = values.sort_by { |a| a[:time] }
      end.to_s
      output
    end

    # Check if Splunk returns any results for queries containing special filtering errors
    def matches_error_filters?(parsed_event, from)
      return false unless parsed_event.respond_to?('status') && parsed_event.status == 'ERROR'
      errors_to_match = self.errors_to_match
      return false if errors_to_match.nil? || errors_to_match.empty?
      query = error_filter_query(parsed_event, from, errors_to_match)
      results = execute_query(query).parsedResults
      total = results.first.total if results.respond_to?(:first) && results.first.respond_to?(:total)
      Integer(total) > 0 rescue false
    end

    def execution_hash(search_result, from)
      {
        :project_pid => search_result.project_id,
        :schedule_id => search_result.schedule_id,
        :request_id => search_result.request_id,
        :clover_graph => search_result.respond_to?('clover_graph') ? Helper.extract_graph_name(search_result.clover_graph) : nil,
        :mode => search_result.respond_to?('mode') ? Helper.extract_mode(search_result.mode) : nil,
        :status => search_result.status,
        :time => DateTime.strptime(search_result._time, '%Y-%m-%dT%H:%M:%S.%L%z'),
        :error_text => find_error_log(search_result, from),
        :matches_filter_errors => matches_error_filters?(search_result, from)
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
