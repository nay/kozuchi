namespace :spec do
  require 'spec/rake/spectask'

  def last_specs
    last_time = nil
    FileList['spec/**/*_spec.rb'].each do |path|
      timestamp = File.mtime(path)
      last_time = timestamp if last_time.nil? || last_time < timestamp
    end
    FileList['spec/**/*_spec.rb'].select do |path|
      File.mtime(path) == last_time
    end
  end

  def recent_specs(touched_since)
    recent_specs = FileList['app/**/*.rb'].map do |path|
      if File.mtime(path) > touched_since
        spec = File.join('spec', File.dirname(path).split("/")[1..-1].join('/'),
          "#{File.basename(path, '.rb')}_spec.rb")
        spec if File.exists?(spec)
      end
    end.compact
    recent_specs += FileList['spec/**/*_spec.rb'].select do |path|
      File.mtime(path) > touched_since
    end.uniq
  end

  desc 'Run last specs'
  Spec::Rake::SpecTask.new(:last) do |t|
    t.spec_opts = ['--options', "\"#{RAILS_ROOT}/spec/spec.opts\""]
    #t.spec_opts = ["--format","specdoc","--color"]
    t.spec_files = last_specs
  end


  desc 'Run recent specs'
  Spec::Rake::SpecTask.new(:recent) do |t|
    t.spec_opts = ['--options', "\"#{RAILS_ROOT}/spec/spec.opts\""]
    #t.spec_opts = ["--format","specdoc","--color"]
    t.spec_files = recent_specs(Time.now - 600) # 10 min.
  end
end