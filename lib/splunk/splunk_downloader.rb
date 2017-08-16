require 'splunk-client'
require 'nokogiri'
require 'benchmark'

module SLAWatcher

  class SplunkDownloader


    def initialize(username, hostname)

      password = PasswordManagerApi::Password.get_password_by_name(username.split('|').first, username.split('|').last)
      @splunk = SplunkClient.new(username.split('|').last, password, hostname)

      @last_runs_query = <<-EOS
      earliest=%START_TIME% latest=%END_TIME% source=/mnt/log/gdc-java sourcetype=log4j eventtype=MSF
      (component=workers.data-loader com.gooddata.msf.util.ScheduleExecutionUpdater) OR (action=process_run schedule_id="*")
      (%PIDS%)
      | rex "(clover_graph|executable)=(?<clover_graph>[^=]+) [^=]+=" | eval clover_graph=if(component=="workers.data-loader", "DATALOAD", clover_graph)
      | rex "Updated execution: /gdc/projects/[^/ ]+/schedules/(?<schedule_id>[^/ ]+)/executions/"
      | rex field=request_id "^(?<request_id>[^ ]*)"
      | eval status=coalesce(case(status=="RUNNING", "STARTED", status=="OK", "FINISHED"), status)
      | table project_id schedule_id request_id clover_graph mode status _time type
      EOS

      @ONE_QUERY_LIMIT = 300

    end


    def execute_query(query)
      # Create the Search
      search = @splunk.search(query)
      @@log.info("splunk query: #{query}")
      #puts query
      sleep(1)
      search.wait # Blocks until the search returns
      search
    end


    def load_runs(from, to, projects)
      project_strings = []
      @@log.info 'Query initialization' + Benchmark.measure {
        0.step(projects.length - 1, @ONE_QUERY_LIMIT) do |i|
          project_strings.push projects[i, @ONE_QUERY_LIMIT].map {|p| "project_id=#{p.project_pid}"}
        end
      }.to_s

      values = []
      project_strings.each do |temp|
        query = @last_runs_query.sub('%PIDS%', temp.join(' OR '))
        query = query.sub('%START_TIME%', from.strftime('%m/%d/%Y:%H:%M:%S'))
        query = query.sub('%END_TIME%', to.strftime('%m/%d/%Y:%H:%M:%S'))
        result = nil
        @@log.info 'Query execution' + Benchmark.measure {
          result = execute_query(query)
        }.to_s
        @@log.info 'Query parsing' + Benchmark.measure {
          result.parsedResults.each do |p|
            values.push({:project_pid => p.project_id,
                         :schedule_id => p.schedule_id,
                         :request_id => p.request_id,
                         :clover_graph => p.respond_to?('clover_graph') ? Helper.extract_graph_name(p.clover_graph) : nil,
                         :mode => p.respond_to?('mode') ? Helper.extract_mode(p.mode) : nil,
                         :status => p.status,
                         :time => DateTime.strptime(p._time, '%Y-%m-%dT%H:%M:%S.%L%z')})
          end
        }.to_s
      end
      output = nil
      @@log.info 'Query sorting' + Benchmark.measure {
        output = values.sort { |a, b| a[:time] <=> b[:time] }
      }.to_s
      output
    end


  end


end
