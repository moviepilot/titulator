require 'titulator/version'

require 'pry'
require 'imdb'

module Titulator

  def self.files
    f = []
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

Titulator.files.each { |f| require f }