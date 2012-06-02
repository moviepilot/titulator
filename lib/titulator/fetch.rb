module Titulator

  class Fetch
    attr_accessor :config

    def initialize(config = nil)
      @config = config || DefaultConfig.instance
    end

    def imdb_movies(query)
      Imdb::Search.new(query).movies
    end

    def imdb_movie_id(query)
      if query.size == 0 then nil else imdb_movies(query)[0].id end
    end

    def new_client
      XMLRPC::Client.new_from_uri config.opensubtitles_uri
    end

  end

end