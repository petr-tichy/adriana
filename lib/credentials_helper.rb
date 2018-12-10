class CredentialsHelper
  @config = nil
  class << self
    def get(config_key)
      config_path = Rails.root.join('config', 'config.json')
      fail 'The file config/config.json doesn\'t exist.' unless File.exist?(config_path)
      @config ||= JSON.load(config_path)
      @config[config_key]
    end

    def connect_to_passman(address, port, key)
      PasswordManagerApi::PasswordManager.connect(address, port, key)
    end

    def load_resource_credentials(resource)
      $log.info 'Loading resource from Password Manager'
      resource_array = resource.split('|')
      username = resource_array[1]
      password = PasswordManagerApi::Password.get_password_by_name(resource_array[0], resource_array[1])
      $log.info 'Resource loaded successfully'
      [username, password]
    end
  end
end