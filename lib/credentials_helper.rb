class CredentialsHelper
  @config = nil
  class << self
    def get(config_key)
      config_path = Rails.root.join('config', 'config.json')
      fail 'The file config/config.json doesn\'t exist.' unless File.exist?(config_path)
      @config ||= JSON.load(config_path)
      @config[config_key]
    end
  end
end