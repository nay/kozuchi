require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

desc 'Default: run unit tests.'
task :default => :spec

desc 'Run rspec of the sub_resources plugin.'
begin
  require 'spec'
  require 'spec/rake/spectask'
  Spec::Rake::SpecTask.new(:spec) do |t|
    spec_dir = File.join(File.dirname(__FILE__), 'spec')
    t.spec_opts = File.read(File.join(spec_dir, 'spec.opts')).split
    t.spec_files = FileList[File.join(spec_dir, '**', '*_spec.rb')]
  end
rescue LoadError
  warn "RSpec is not installed. Some tasks were skipped. please install rspec"
end

desc 'Test the sub_resources plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

desc 'Generate documentation for the sub_resources plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'SubResources'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
