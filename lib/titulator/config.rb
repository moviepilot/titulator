module Titulator

	class Config
		attr_accessor :opensubtitles_uri

    def initialize(config = {})
      @opensubtitles_uri = config[:opensubtitles_uri] || 'http://api.opensubtitles.org/xml-rpc'
    end
	end

  class DefaultConfig < Config
    include Singleton
  end

end
