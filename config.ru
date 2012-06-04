begin
  require 'pry'
  IRB = Pry
  Pry.load_rc
rescue
  nil
end

require 'haml'
require 'sinatra'
require 'faraday'
require 'typhoeus' if RUBY_ENGINE.to_sym != :jruby
require 'rack/cache'
require 'sinatra/json'
require 'sinatra/namespace'
require 'sinatra/config_file'

$LOAD_PATH << File.join(File.dirname(__FILE__), 'app')

require 'titulator'
require 'titulator/app'

run Titulator::App.new