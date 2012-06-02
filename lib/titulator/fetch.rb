module Titulator

  class Fetch
    attr_reader :config

    def initialize(config = nil)
      @config = config || DefaultConfig.instance
    end

    def imdb_movies(query)
      Imdb::Search.new(query).movies
    end

    def imdb_movie_id(query)
      if query.size == 0 then nil else imdb_movies(query)[0].id end
    end

    def osdb_info
      OSDb::Server.new(@config.opensubtitles_api).info
    end

    def osdb_search(lang, imdb_id)
      osdb   = OSDb::Server.new @config.opensubtitles_api
      token  = osdb.login
      lang   = if lang.size == 3 then lang else ISO_639.find(lang)[0] end
      begin
        result = osdb.search_subtitles imdbid: imdb_id, sublanguageid: lang, token: token
        # TODO check if we should reverse the array
        return result
      ensure
        osdb.logout
      end
    end

    def load_osdb(osdb)

    end
  end

end