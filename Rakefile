#!/usr/bin/env rake

# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require 'bundler'
Bundler.setup
Bundler::GemHelper.install_tasks

Dir['lib/tasks/*.rake'].each { |rake| load rake }

require 'rspec/core'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

desc  "Run all specs with rcov"
RSpec::Core::RakeTask.new(:rcov) do |t|
  t.rcov = true
  t.rcov_opts = %w{--rails --exclude osx\/objc,gems\/,spec\/,features\/}
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "chanko"
    gemspec.summary = "Extend rails application"
    gemspec.email = "morita.shingo@gmail.com"
    gemspec.homepage = ""
    gemspec.description = "Extend rails application "
    gemspec.authors = ["MORITA shingo"]
  end
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end

