require 'rubygems'

unless ENV['BUNDLE_GEMFILE']
  raise "Select Gemfile_x.rb from gemfiles dir then set BUNDLE_GEMFILE"
end

require 'bundler/setup'

$:.unshift File.expand_path('../../../../lib', __FILE__)
