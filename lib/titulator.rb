require 'titulator/version'

begin
  require 'yajl'
  require 'json'
rescue
  require 'json'
end

begin
  require 'pry'
  IRB = Pry
rescue
  nil
end

require 'rdoc'
require 'imdb'
require 'osdb'
require 'thin'
require 'puma'
require 'haml'
require 'iconv'
require 'iso-639'
require 'singleton'
require 'bin_search'

require 'sinatra'
require 'faraday'
require 'rack/cache'
require 'sinatra/json'
require 'sinatra/namespace'

module Titulator

  def self.files
    f = []
    f << 'titulator/config'
    f << 'titulator/parse'
    f << 'titulator/fetch'
    f << 'titulator/app'
    f
  end

  def self.load_relative(f)
    path = "#{File.join(File.dirname(caller[0]), f)}.rb"
    load path
  end

  def self.reload!
    files.each { |f| load_relative f }
  end

end

Titulator.files.each { |f| require_relative f }