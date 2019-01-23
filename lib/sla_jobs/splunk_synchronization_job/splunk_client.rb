require 'json'
require 'net/https'
require 'uri'
require_relative 'splunk_errors'
require_relative 'splunk_job'

module SplunkSynchronizationJob
  class SplunkClient
    def initialize(username, password, host, port = 8089, proxy_url = '', read_timeout = 60, use_ssl = true)
      @username = username
      @password = password
      @host = host
      @port = port
      @read_timeout = read_timeout
      @use_ssl = use_ssl
      @proxy_url = URI(proxy_url) unless proxy_url.to_s.empty?

      session_key = get_session_key

      raise SplunkSessionError, 'Session key is invalid. Please check your username, password and host' if session_key.to_s.empty?
      @session_header = {'authorization' => "Splunk #{session_key}"}
    end

    def search(search)
      json = splunk_post_request('/services/search/jobs', "search=#{CGI.escape("search #{search}")}&output_mode=json", @session_header).body
      @doc = JSON.parse(json)
      SplunkJob.new(@doc.dig('sid'), self)
    end

    def get_search_job_body(sid)
      JSON.parse(splunk_get_request("/services/search/jobs/#{sid}?output_mode=json").body)
    end

    def get_search_done_status(sid)
      @doc = get_search_job_body(sid)
      @doc.dig('entry', 0, 'content', 'isDone')
    end

    def get_search_failed_status(sid)
      @doc = get_search_job_body(sid)
      @doc.dig('entry', 0, 'content', 'isFailed')
    end

    def get_search_messages(sid)
      @doc = get_search_job_body(sid)
      @doc.dig('entry', 0, 'content', 'messages')
    end

    def get_search_results(sid, max_results = 50_000, offset = 0)
      url = "/services/search/jobs/#{sid}/results?count=#{max_results}&offset=#{offset}&output_mode=json"
      splunk_get_request(url)
    end

    def control_job(sid, action)
      @doc = JSON.parse(splunk_post_request("/services/search/jobs/#{sid}/control", "action=#{CGI::escape(action)}&output_mode=json", @session_header).body)
    end

    private

    def splunk_http_request
      http = @proxy_url ? Net::HTTP.new(@host, @port, @proxy_url.host, @proxy_url.port) : Net::HTTP.new(@host, @port)
      http.read_timeout = @read_timeout
      http.use_ssl = @use_ssl
      http
    end

    def splunk_get_request(path)
      splunk_http_request.get(path, @session_header.merge('Content-Type' => 'application/x-www-form-urlencoded'))
    end

    def splunk_post_request(path, data = nil, headers = nil)
      splunk_http_request.post(path, data, headers)
    end

    def get_session_key
      json = splunk_post_request('/services/auth/login', "username=#{@username}&password=#{@password}&output_mode=json").body
      JSON.parse(json).dig('sessionKey')
    end
  end
end