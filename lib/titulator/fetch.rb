module Titulator


  module Fetch

    def self.imdb_movies(query)
      Imdb::Search.new(query).movies
    end

    def self.imdb_movie_id(query)
      if query.size == 0 then nil else imdb_movies(query)[0].id end
    end

  end

end