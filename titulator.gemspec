# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'titulator/version'

Gem::Specification.new do |s|
  s.name        = 'titulator'
  s.version     = Titulator::VERSION
  s.authors     = ['Stefan Plantikow']
  s.email       = ['stefanp@moviepilot.com']
  s.homepage    = ''
  s.summary     = %q{movie subtitle fetcher}
  s.description = %q{Fetch movie subtitles and compare movies according to their language}

  s.rubyforge_project = "titulator"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'yard'

  case RUBY_ENGINE.to_sym
    when :jruby then s.add_development_dependency 'maruku'
    else s.add_development_dependency 'redcarpet'
  end

  s.add_runtime_dependency 'pry'
  s.add_runtime_dependency 'imdb'
  s.add_runtime_dependency 'osdb'
  s.add_runtime_dependency 'iso-639'
  s.add_runtime_dependency 'libarchive'
end
