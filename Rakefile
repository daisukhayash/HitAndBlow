# -*- encoding: utf-8 -*-

require 'rubygems'
require 'rake'
libdir = File.join(File.dirname(__FILE__), "lib")
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)
 
require 'rspec/core'
require 'rspec/core/rake_task'
 
task :default => :spec
 
desc "Run all specs in spec directory"
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = 'spec/*.rb'
  spec.rspec_opts = ['-cfs']
end

desc "Run digit_spec"
RSpec::Core::RakeTask.new(:digit) do |spec|
  spec.pattern = 'spec/digit_spec.rb'
  spec.rspec_opts = ['-cfs']
end

desc "Run candidate_spec"
RSpec::Core::RakeTask.new(:candidate) do |spec|
  spec.pattern = 'spec/candidate_spec.rb'
  spec.rspec_opts = ['-cfs']
end
