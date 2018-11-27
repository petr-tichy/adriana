class CredentialsHelper
  @config = nil
  class << self
    def get(config_key)
      config_path = Rails.root.join('config', 'config.json')
      @config ||= JSON.load(config_path)
      @config[config_key]
    end
  end
end