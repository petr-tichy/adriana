require 'restforce'
require_relative '../job_exception'
require_relative '../job_helper'
require 'pry'

module SalesforceSynchronizationJob
  class SalesforceSynchronizationJob
    JOB_TYPE = 'salesforce_synchronization'.freeze
    attr_accessor :credentials, :sf_client

    def initialize(credentials)
      @credentials = credentials
    end

    def connect
      #self.class.connect_to_sf
    end

    def run
      client = Restforce.new(username: 'integration.internal@gooddata.com',
                             password: '',
                             security_token: '',
                             client_id: '',
                             client_secret: '',
                             api_version: '41.0')
      binding.pry
      output = client.query("SELECT Id, Managed__c, Platform_Token__c FROM Contract")
      client.update('Contract', Id: contract_id, Managed__c: true)
    end

    class << self
      def connect_to_sf
        connection_params = %i[client_id client_secret username password security_token]
        fail "All of the following parameters must be provided for the Salesforce client: #{connection_params}" unless connection_params.all? { |x| !@credentials[:salesforce][x].to_s.empty? }
        @sf_client = Restforce.new(connection_params.map { |x| [x, @credentials[:salesforce][x]] }.to_h.merge(api_version: '41.0'))
      end
    end
  end
end