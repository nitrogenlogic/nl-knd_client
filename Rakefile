require "bundler/gem_tasks"
require 'rake/extensiontask'

task :default => :spec

Rake::ExtensionTask.new 'kinutils' do |ext|
  ext.name = 'kinutils'
  ext.ext_dir = 'ext/kinutils'
  ext.lib_dir = 'lib/nl/knd_client'
end
