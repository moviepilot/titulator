module Titulator

  class App < Sinatra::Application

    helpers do
      def script_url(env, url)
        protocol = env['rack.url_scheme']
        server   = env['SERVER_NAME']
        port     = env['SERVER_PORT']
        path     = env['SCRIPT_NAME']
        path     = "#{path}#{url}"
        return "#{protocol}://#{server}:#{port}" if path.size == 0
        return "#{protocol}://#{server}:#{port}#{path}" if path[0] == '/'
        return "#{protocol}://#{server}:#{port}/#{path}"
      end
    end

    namespace '/api' do

      use Rack::Cache,
        :verbose          => true,
        :allow_revalidate => false,
        :allow_reload     => false,
        :metastore        => 'file:cache/meta',
        :entitystore      => 'file:cache/body'

      before do
        content_type 'application/json'
        cache_control :public, :must_revalidate, :max_age => 36000
      end

      get '/movie_id' do
        fetch  = Fetch.new
        id     = fetch.imdb_movie_id params[:q]
        result = { id: id }

        status 200
        json result
      end

      get '/subtitles/:lang/:imdb_req' do |lang, imdb_req|
        fetch   = Fetch.new
        unless (imdb_req.to_i rescue 0) > 0
          halt 400 if imdb_req.include?(' ')
          movie    = fetch.imdb_movie imdb_req
          imdb_id  = movie.id
        else
          imdb_id = imdb_req
          movie   = fetch.imdb_movie_by_id imdb_id
        end
        data   = fetch.osdb_subtitles lang, imdb_id
        result = {
          :title => movie.title,
          :id    => imdb_id,
          :lang  => lang,
          :data  => data,
          :size  => data.size
        }
        if data.size > 0
          result[:start] = data.first.start
          result[:stop]  = data.last.stop
        end

        status 200
        json result
      end

    end

    get '/api/selected_subtitles/:lang/:imdb_req' do |lang, imdb_req|
      content_type 'application/json'
      cache_control :no_cache

      start    = params[:start]
      stop     = params[:stop]
      grep     = params[:grep]
      match    = params[:match]
      limit    = params[:limit].to_i rescue 0
      range    = params[:range].to_i rescue 0
      merge    = {}
      imdb_req = imdb_req.gsub '_', ' ' unless (imdb_req.to_i rescue 0) > 0

      data_url  = script_url(env, "/api/subtitles/#{lang}/#{imdb_req}")
      data_resp = Faraday.get data_url
      result    = JSON.parse data_resp.body
      subs      = result['data'].map { |item| Caption.from_json item }

      selection = nil
      if range > 0 && (grep || match)
        ranges = []
        subs.each_with_index do |c, i| ranges << [c, i] end
        ranges = ranges.select { |a| a[0].grep grep } if grep
        ranges = ranges.select { |a| a[0].match match } if match
        ranges.map! do |a|
          fst = [0, a[1]-range].max
          snd = [a[1]+range, subs.size-1].min
          { quotes:  subs[fst..snd] }
        end
        merge[:size] = ranges.size
        selection = ranges
      else
        subs = subs.select { |c| c.grep grep } if grep
        subs = subs.select { |c| c.match match } if match
        merge[:size] = subs.size if grep || match
        selection = subs
      end
      result.merge! merge
      result['data'] = if limit > 0
        then selection[0..[selection.size, limit].min]
        else selection end

      status 200
      json result
    end
  end

end