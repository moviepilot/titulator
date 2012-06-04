module Titulator

  class App < Sinatra::Application

    config_file 'config/app.yml'

    helpers do
      def script_url(env)
        protocol = env['rack.url_scheme']
        server   = env['SERVER_NAME']
        port     = env['SERVER_PORT']
        path     = env['SCRIPT_NAME']
        url = if path.size == 0
                then "#{protocol}://#{server}:#{port}"
                else "#{protocol}://#{server}:#{port}#{path}" end
        Faraday.new(url) do |builder|
           builder.request :url_encoded
           builder.adapter :typhoeus if RUBY_ENGINE.to_sym != :jruby
        end
      end

      def debug_hook(scope = nil)
        scope ||= bindings
        debug   = request.env['HTTP_X_DEBUG_CONSOLE'] || params['debug']
        debug   = debug.to_sym if debug
        case debug
        when :local then scope.pry
        when :remote then scope.remote_pry
        end
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
        cache_control :public, :must_revalidate, :max_age => settings.api[:max_age]
      end

      get '/movie_id' do
        debug_hook binding

        fetch    = Fetch.new
        imdb_req = params[:q]
        movie    = fetch.imdb_movie imdb_req
        halt 404 unless movie

        result = { id: movie.id, title: movie.title }

        status 200
        json result
      end

      get '/subtitles/:lang/:imdb_req' do |lang, imdb_req|
        debug_hook binding

        fetch    = Fetch.new
        imdb_req = imdb_req.gsub '_', ' '
        movie    = JSON.parse script_url(env).get('/api/movie_id', q: imdb_req).body
        imdb_id  = movie['id']
        title    = movie['title']

        data     = fetch.osdb_subtitles lang, imdb_id
        result   = {
          :title => title,
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
      debug_hook binding

      start    = params[:start]
      stop     = params[:stop]
      grep     = params[:grep]
      match    = params[:match]
      limit    = params[:limit].to_i rescue 0
      range    = params[:range].to_i rescue 0

      imdb_req  = imdb_req.gsub '_', ' ' unless (imdb_req.to_i rescue 0) > 0
      result    = JSON.parse script_url(env).get("/api/subtitles/#{lang}/#{imdb_req}").body
      subs      = result['data'].map { |item| Caption.from_json item }

      selection  = if range > 0 && (grep || match)
        ranges = []
        subs.each_with_index do |c, i| ranges << [c, i] end
        ranges = ranges.select { |a| a[0].grep grep } if grep
        ranges = ranges.select { |a| a[0].match match } if match
        ranges.map! do |a|
          fst = [0, a[1]-range].max
          snd = [a[1]+range, subs.size-1].min
          { quotes:  subs[fst..snd] }
        end
        result[:size] = ranges.size
        ranges
      else
        subs = subs.select { |c| c.grep grep } if grep
        subs = subs.select { |c| c.match match } if match
        result[:size] = subs.size if grep || match
        subs
      end
      result['data'] = if limit > 0
        then selection[0..[selection.size, limit].min]
        else selection end

      status 200
      json result
    end
  end

end