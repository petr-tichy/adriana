require 'splunk-client'
require 'nokogiri'
require 'benchmark'

module SLAWatcher

  class SplunkDownloader


    def initialize(username, hostname)

      password = PasswordManagerApi::Password.get_password_by_name(username.split('|').first, username.split('|').last)
      @splunk = SplunkClient.new(username.split('|').last, password, hostname)

      @last_runs_query = <<-EOS
      source="/mnt/log/gdc-java" sourcetype=log4j eventtype=MSF earliest=%START_TIME% latest=%END_TIME% action=process_run (status=STARTED OR status=FINISHED OR status=ERROR) (%PIDS%)
      | rex "clover_graph=(?<clover_graph>[^=]+) [^=]+=" | rex "executable=(?<executable>[^=]+) [^=]+=" | eval clover_graph=coalesce(executable, clover_graph)
      | table project_id schedule_id request_id clover_graph mode status _time
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
      temp_project_string = []


      @@log.info 'Query initialization' + Benchmark.measure {
        projects.each do |p|
          temp_project_string.push("project_id=#{p.project_pid}")
          if temp_project_string.count == @ONE_QUERY_LIMIT
            project_strings << temp_project_string
            temp_project_string = []
          end
        end
        project_strings << temp_project_string
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
