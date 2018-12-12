require_relative 'sla_jobs/job_exception'

class CredentialsHelper
  @config = nil
  class << self
    def get(config_key)
      config_path = Rails.root.join('config', 'config.json')
      fail 'The file config/config.json doesn\'t exist.' unless File.exist?(config_path)
      @config ||= JSON.load(config_path)
      @config[config_key].tap { |x| fail "The config doesn't contain the key #{config_key}." unless x }
    end

    def connect_to_passman(address, port, key)
      PasswordManagerApi::PasswordManager.connect(address, port, key)
    end

    def load_resource_credentials(resource)
      $log.info 'Loading resource from Password Manager'
      resource_array = resource.split('|')
      username = resource_array[1]
      begin
        password = PasswordManagerApi::Password.get_password_by_name(resource_array[0], resource_array[1])
        raise PassmanCredentialsError, 'Couldn\'t obtain password from Passman' if password.to_s.empty?
      rescue NoMethodError
        raise PassmanCredentialsError, 'Couldn\'t obtain password from Passman'
      end
      $log.info 'Resource loaded successfully'
      [username, password]
    end
  end
end