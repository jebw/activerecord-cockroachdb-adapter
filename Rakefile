require "bundler/gem_tasks"
require 'rake/testtask'

require File.expand_path(File.dirname(__FILE__)) + "/test/config"
require File.expand_path(File.dirname(__FILE__)) + "/test/support/config"

desc 'Run cockroachdb tests by default'
task :default => :test

desc 'Run cockroachdb tests'
task :test => :test_cockroachdb

desc 'Build CockroachDB test databases'
namespace :db do
  task :create => ['db:cockroachdb:build']
  task :drop => ['db:cockroachdb:drop']
end

%w( cockroachdb ).each do |adapter|
  namespace :test do
    Rake::TestTask.new(adapter => "#{adapter}:env") { |t|
      t.libs << 'test'
      t.test_files = Dir.glob( "test/cases/**/*_test.rb" ).sort

      t.warning = true
      t.verbose = true
    }
  end

  namespace adapter do
    task :test => "test_#{adapter}"

    # Set the connection environment for the adapter
    task(:env) { ENV['ARCONN'] = adapter }
  end

  # Make sure the adapter test evaluates the env setting task
  task "test_#{adapter}" => ["#{adapter}:env", "test:#{adapter}"]
end

namespace :db do
  namespace :cockroachdb do
    desc 'Build the CockroachDB test databases'
    task :build do
      config = ARTest.config['connections']['cockroachdb']
      %x( cockroachdb sql --user #{config['arunit']['username']} -e "CREATE DATABASE #{config['arunit']['database']}" )
    end

    desc 'Drop the CockroachDB test databases'
    task :drop do
      config = ARTest.config['connections']['cockroachdb']
      %x( cockroachdb sql --user #{config['arunit']['username']} -e "DROP DATABASE #{config['arunit']['database']}" )
    end

    desc 'Rebuild the CockroachDB test databases'
    task :rebuild => [:drop, :build]
  end
end

task :build_cockroachdb_databases => 'db:cockroachdb:build'
task :drop_cockroachdb_databases => 'db:cockroachdb:drop'
task :rebuild_cockroachdb_databases => 'db:cockroachdb:rebuild'
