require 'restforce'
require_relative '../job_exception'
require_relative '../job_helper'

module SalesforceSynchronizationJob
  class SalesforceSynchronizationJob
    JOB_TYPE = 'salesforce_synchronization'.freeze
    SF_MONITORING_FIELD = 'Managed__c'.freeze
    SF_TOKEN_FIELD = 'Platform_Token__c'.freeze

    attr_accessor :credentials, :sf_client

    def initialize(credentials)
      @credentials = credentials
    end

    def connect
      connect_to_sf
    end

    def run
      @sf_contracts = sf_contract_mapping
      $log.info "Processing #{live_contracts.size} monitored contracts."
      live_contracts.each do |contract|
        process_contract_monitoring(contract, monitoring_value: true)
      end
      $log.info "Processing #{deleted_contracts.size} non-monitored contracts."
      deleted_contracts.each do |contract|
        process_contract_monitoring(contract, monitoring_value: false)
      end
    end

    def process_contract_monitoring(contract, monitoring_value: true)
      reference_name = "#{contract.id} - #{contract.name}"
      local_token = contract.token
      if local_token.to_s.empty?
        $log.warn "Contract #{reference_name} has no 'token' value and cannot be synchronized."
        return false
      end
      unless @sf_contracts.key?(local_token)
        $log.warn "Cannot find SF contract with platform token #{local_token}."
        return false
      end
      sf_object = @sf_contracts[local_token]
      return if sf_object[:sf_monitoring_field] == monitoring_value
      $log.info "Updating Contract #{sf_object[:id]} - setting #{SF_MONITORING_FIELD} to #{monitoring_value}."
      @sf_client.update('Contract', :Id => sf_object[:id], SF_MONITORING_FIELD.to_sym => monitoring_value)
      true
    end

    # Contracts are mapped by platform token field
    def sf_contract_mapping
      output = @sf_client.query("SELECT Id, #{SF_MONITORING_FIELD}, #{SF_TOKEN_FIELD} FROM Contract")
      tokens = output.map { |x| [x[SF_TOKEN_FIELD], x['Id']].flatten }
      non_unique = tokens.select { |x| tokens.count { |y| y[0] == x[0] } > 1 }
      fail "There are multiple contracts for a single token - #{non_unique.map { |x| x.join '-' }.join(', ')}. Aborting." if non_unique.any?
      output.map { |x| [x[SF_TOKEN_FIELD], {id: x['Id'], sf_monitoring_field: x[SF_MONITORING_FIELD]}] }.to_h
    end

    def live_contracts
      Contract.all.where(is_deleted: false)
    end

    def deleted_contracts
      Contract.all.where(is_deleted: true)
    end

    def connect_to_sf
      connection_params = %i[client_id client_secret username password security_token]
      fail "All of the following parameters must be provided for the Salesforce client: #{connection_params}" if connection_params.any? { |x| @credentials.dig(:salesforce, x).to_s.empty? }
      @sf_client = Restforce.new(connection_params.map { |x| [x, @credentials[:salesforce][x]] }.to_h.merge(api_version: '41.0'))
    end
  end
end