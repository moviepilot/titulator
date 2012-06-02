module Titulator

	class Config
    def initialize(config = {})
      default_hash = {
        :opensubtitles_api => {
          :host => 'api.opensubtitles.org',
          :path => '/xml-rpc',
          :timeout => 60,
          :useragent => 'OS Test User Agent'
        }
      }
      @config_hash = config.merge default_hash
    end

    def opensubtitles_api ; @config_hash[:opensubtitles_api] end
	end

  class DefaultConfig < Config
    include Singleton
  end

end
