module Titulator

  class App < Sinatra::Application

    use Rack::Cache

    get '/movie_id' do
      fetch  = Fetch.new
      id     = fetch.imdb_movie_id(params['q'])
      result = { id: id }
      status 200
      result.to_json
    end

    get '/subtitles/:lang/:imdb_id' do |lang, imdb_id|
      content_type (if html = (request.content_type == 'text/html')
        then 'text/html'
        else 'application/json' end)

      start   = params['start']
      stop    = params['stop']
      grep    = params['grep']
      match   = params['match']
      limit   = params['limit'].to_i rescue 0
      range   = params['range'].to_i rescue 0
      merge   = {}
      fetch   = Fetch.new
      unless (imdb_id.to_i rescue 0) > 0
        imdb_id = imdb_id.gsub '_', ' '
        movie   = fetch.imdb_movie(imdb_id)
        imdb_id = movie.id
      else
        movie   = fetch.imdb_movie_by_id(imdb_id)
      end
      subs    = fetch.osdb_subtitles lang, imdb_id, start, stop
      return [].to_json if subs.size == 0
      result  = if range > 0 && (grep || match)
        ranges = []
        subs.each_with_index do |c, i| ranges << [c, i] end
        ranges = ranges.select { |a| a[0].grep grep } if grep
        ranges = ranges.select { |a| a[0].match match } if match
        ranges.map! do |a|
          fst = [0, a[1]-range].max
          snd = [a[1]+range, subs.size-1].min
          { quotes:  subs[fst..snd] }
        end
        merge[:num_quotes_found] = ranges.size
        ranges
      else
        subs = subs.select { |c| c.grep grep } if grep
        subs = subs.select { |c| c.match match } if match
        merge[:num_quotes_found] = subs.size if grep || match
        subs
      end
      status 200
      result = result[0..[result.size, limit].min] if limit > 0
      result = { result: result, title: movie.title }
      result.merge! merge

      # TODO make beautiful
      if html
        '<html></html>'
      else
        cache_control :public, :max_age => 3600
        status 2000
        result.to_json
      end
    end
  end

end