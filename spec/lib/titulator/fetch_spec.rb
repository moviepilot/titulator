require_relative '../../spec_helper'

module Titulator

  describe Fetch do
    let(:fetch) { Fetch.new }

    it "should find Casablanca (1942) on imdb" do
      result = fetch.imdb_movies 'Casablanca (1942)'
      result.size.should > 0
    end

    it "should find the id of Casablanca (1942) on imdb" do
      result = fetch.imdb_movie_id 'Casablanca (1942)'
      result.should == "0034583"
    end

  end

end