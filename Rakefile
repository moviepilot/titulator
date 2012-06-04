require 'bundler/gem_tasks'

require 'rspec'
require 'rspec/core/rake_task'

require 'rdoc'

require 'yard'
require 'yard/rake/yardoc_task'

require 'pry'
IRB = Pry

desc 'Run all rspecs'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.fail_on_error = true
  spec.verbose       = false
#  spec.rspec_opts    = ['--backtrace']
end

desc 'Run yardoc over project sources'
YARD::Rake::YardocTask.new(:doc) do |t|
  t.options = ['--verbose']
  t.files   = ['lib/**/*.rb', '-', 'README.md', 'AUTHORS', 'LICENSE.txt']
  t.files  << 'CHANGELOG.md'
  t.files  << 'ROADMAP.md'
end

desc 'Run pry console'
task :console do
  require 'bundler'
  Bundler.require

  module Titulator
    binding.pry
  end
end

task :pry => :console
task :docs => :doc
task :specs => :spec

task :default => [:spec, :doc] do
  puts 'Finished running specs and building docs.  Run rake console to enter an interactive shell.'
end