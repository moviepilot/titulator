module Titulator

	class Config
    def initialize(config = {})
      default_hash = {
        :host => 'api.opensubtitles.org',
        :path => '/xml-rpc',
        :timeout => 60,
        :useragent => 'OS Test User Agent'
      }
      # TODO check that this works
      default_hash[:useragent] = ENV['TITULATOR_AGENT'] if ENV['TITULATOR_AGENT']
      default_hash[:username] = ENV['TITULATOR_NAME'] if ENV['TITULATOR_NAME']
      default_hash[:userpass] = ENV['TITULATOR_PASS'] if ENV['TITULATOR_PASS']
      default_hash = { opensubtitles_api: default_hash }
      @config_hash = config.merge default_hash
    end

    def opensubtitles_api ; @config_hash[:opensubtitles_api] end
	end

  class DefaultConfig < Config
    include Singleton
  end

end
