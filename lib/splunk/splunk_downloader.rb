require 'splunk-client'
require 'nokogiri'

module SLAWatcher

  class SplunkDownloader


    def initialize(username, password,hostname)
      @splunk = SplunkClient.new(username ,password, hostname)

      @last_runs_query = 'eventtype=MSF mode (component="workers.clover-executor" OR component="workers.clover-status") starttime=%START_TIME% endtime=%END_TIME%  action=process_run (status=STARTED OR status=FINISHED OR status=ERROR) ( %PIDS% )
                        | fields project_id, request_id,transformation_id, clover_graph, mode, status, _time
                        | table project_id, request_id,transformation_id, clover_graph, mode, status, _time'

      #@start_query = 'eventtype=MSF mode component="workers.clover-executor" starttime=%START_TIME% endtime=%END_TIME%  action=worker_run status=STARTED ( %PIDS% ) | fields project_id, request_id,transformation_id, clover_graph, mode, status, _time | table project_id, request_id,transformation_id, clover_graph, mode, status, _time'
      #@finish_error_query = ''


    end


    def execute_query(query)
      # Create the Search
      search = @splunk.search(query)
      puts query
      sleep(10)
      search.wait # Blocks until the search returns
      search
    end


    def load_runs(from,to,projects)
      project_strings = []
      projects.each do |p|
         project_strings.push("project_id=#{p.project_pid}")
      end

      query = @last_runs_query.sub("%PIDS%",project_strings.join(" OR "));
      query = query.sub("%START_TIME%",from.strftime("%m/%d/%Y:%H:%M:%S"));
      query = query.sub("%END_TIME%",to.strftime("%m/%d/%Y:%H:%M:%S"));
      result = execute_query(query)

      values = []

      result.parsedResults.each do |p|
        values.push({:project_pid => p.project_id,:request_id => p.request_id, :clover_graph => Helper.extract_graph_name(p.clover_graph), :mode => Helper.extract_mode(p.mode), :status => p.status,:time => DateTime.strptime(p._time,"%Y-%m-%dT%H:%M:%S.%L%z")})
      end
      values.sort{|a,b| a[:time] <=> b[:time]}
    end







  end



end