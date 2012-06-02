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
      raise ArgumentError, 'no language given' if lang.nil?
      raise ArgumentError, 'invalid imdb_id' if imdb_id.nil?
      osdb   = OSDb::Server.new @config.opensubtitles_api
      token  = osdb.login
      lang   = lang.to_s
      lang   = if lang.size == 3 then lang else ISO_639.find(lang)[0] end
      begin
        result = osdb.search_subtitles imdbid: imdb_id, sublanguageid: lang, token: token
        # TODO check if we should reverse the array
        return result
      ensure
        osdb.logout
      end
    end

    def osdb_find_set(lang, imdb_id)
      osdb_select_set osdb_search(lang, imdb_id)
    end

    # Example:
    #   cands=f.osdb_find_set(:en, 499549)
    #
    def osdb_select_set(cands)
      raise ArgumentError, 'Invalid candidate set' if cands.size == 0
      cands[0..cands.first.raw_data['SubSumCD'].to_i - 1]
    end

    def osdb_load_subtitles(cands)
      cands.map do |cand|
        content = Net::HTTP.get_response(cand.url).body
        gz_body = Zlib::GzipReader.new StringIO.new(content), external_encoding: content.encoding
        Parser.parse cand.format.chomp.downcase.to_sym, gz_body.read
      end
    end
  end

end