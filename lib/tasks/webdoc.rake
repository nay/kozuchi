desc "Run webdoc:app"
task :webdoc => 'webdoc:app'

namespace :webdoc do
  desc "Generate summary documents of your application"
  task :app do
    FileUtils.mkpath(File.join(RAILS_ROOT, 'doc', 'web'))
    require File.join(RAILS_ROOT, 'config', 'environment.rb')

    # get controller classes
    controllers = Dir.glob("#{RAILS_ROOT}/app/controllers/**/*_controller.rb").map{|path|
      path=~/#{RAILS_ROOT}\/app\/controllers\/(.*)\.rb/
      $1.classify.constantize
    }

    # remove super classes
    super_controllers = controllers.inject([]) { |list, c| list << c.superclass }
    super_controllers.uniq!
    controllers -= super_controllers

    # generate controller docs
    FileUtils.mkpath(File.join(RAILS_ROOT, 'doc', 'web', 'controllers'))
    controllers.each do |c|
      path = File.join(RAILS_ROOT, 'doc', 'web', 'controllers', *c.to_s.underscore.split('/'))
      FileUtils.mkpath(path)
      File.open(File.join(path, 'index.html'), 'w') do |file|
        file.write("<html>\n")
        file.write("<body>\n")
        file.write("<h1>#{c.to_s}</h1>\n")
        file.write("<h2>Actions</h2>\n")
        file.write("<ul>\n")
        c.action_methods.each do |a|
          file.write("<li>#{a}</li>\n")
        end
        file.write("</ul>\n")
        file.write("</body>\n")
        file.write("</html>\n")
      end
    end

    # generate index
    File.open(File.join(RAILS_ROOT, 'doc', 'web', 'index.html'), 'w') do |file|
      file.write("<html>\n")
      file.write("<body>\n")
      file.write("<h1>#{RAILS_ROOT.split('/').last.humanize} Web Document</h1>\n")
      file.write("<h2>Controllers</h2>\n")
      file.write("<ul>\n")
      controllers.each do |c|
        file.write("<li><a href='controllers/#{c.to_s.underscore}/index.html'>#{c.to_s}</a></li>\n")
      end
      file.write("</ul>\n")
      file.write("</body>\n")
      file.write("</html>\n")
    end
  end
end
