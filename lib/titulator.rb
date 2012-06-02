require 'titulator/version'

require 'pry'
require 'imdb'
require 'singleton'
require 'osdb'
require 'iso-639'

module Titulator

  def self.files
    f = []
    f << 'titulator/config'
    f << 'titulator/fetch'
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