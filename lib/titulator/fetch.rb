module Titulator

  class Fetch
    attr_reader :config

    def initialize(config = nil)
      @config = config || DefaultConfig.instance
    end

    def imdb_movies(query)
      Imdb::Search.new(query).movies
    end

    def imdb_movie(query)
      if query.size == 0 then nil else imdb_movies(query)[0] end
    end

    def imdb_movie_by_id(id)
      Imdb::Movie.new(id)
    end

    def imdb_movie_id(query)
      imdb_movie(query).id rescue nil
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

    # Example:
    #   f.osdb_subtitles(:en, 499549)
    #   f.osdb_subtitles(:en, 133093)
    #
    def osdb_subtitles(lang, imdb_id, start = nil, stop = nil)
      start       = MilliTime.parse(start) if start.is_a?(String)
      start       = MilliTime.new(start) if start.is_a?(Fixnum)
      stop        = MilliTime.parse(stop) if stop.is_a?(String)
      stop        = MilliTime.new(stop) if stop.is_a?(Fixnum)
      cands       = osdb_select_set osdb_search(lang, imdb_id)
      subs        = osdb_load_subtitles cands
      titles      = osdb_join_subtitles subs
      return [] if titles.size == 0
      start_index = if start
        then titles.bin_index(start, :asc) { |a, b| a <=> b.start }
        else 0 end
      return [] if start_index < 0
      stop_index  = if stop
        then [start_index, titles.bin_index(stop, :asc) { |a, b| a <=> b.stop } - 1].max
        else -1 end
      stop_index  = titles.size-1 if stop_index < 0
      raise ArgumentError, 'start > stop' if start_index > stop_index
      titles[start_index..stop_index]
    end

    private

    def osdb_select_set(cands)
      cands = cands.select { |c| c.raw_data['SubFormat'] == 'srt' }
      raise ArgumentError, 'Invalid candidate set' if cands.size == 0
      cands[0..cands.first.raw_data['SubSumCD'].to_i - 1]
    end

    def osdb_load_subtitles(cands)
      subs = cands.map do |cand|
        content = Net::HTTP.get_response(cand.url).body
        gz_body = Zlib::GzipReader.new StringIO.new(content), external_encoding: content.encoding
        Parser.parse cand.format.chomp.downcase.to_sym, gz_body.read
      end
    end

    def osdb_join_subtitles(subs)
      result = []
      shift  = MilliTime::ZERO
      prev   = MilliTime::ZERO
      subs.each do |captions|
        captions.each do |caption|
          caption = caption + shift
          if (caption.start <=> prev) == -1
            shift   = prev
            caption = caption + prev - shift
          end
          result << caption
          prev    = caption.start
        end
      end
      result
    end
  end
end

