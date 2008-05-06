require 'rubygems'
require 'gettext/utils'

namespace :gettext do
  desc 'Update pot/po files.'
  task :updatepo do
    GetText.update_pofiles('kozuchi',
                           Dir.glob("{app,config,lib}/**/*.{rb,rhtml,erb}"),
                           'kozuchi'
                           )
  end

  desc 'Create mo-files'
  task :makemo do
    GetText.create_mofiles(true, 'po', 'locale')
  end
end