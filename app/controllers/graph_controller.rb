class GraphController < ApplicationController 
  GRAPH_TT_FONT = '/usr/local/share/fonts/sazanami-mincho.ttf'

  def pie
    labels = params[:labels].split(',')
    values = params[:values].split(',')

    values.map! do |x|
      x.to_f
    end
#    p labels
#    p values

    colors = [0xFF4040, 0x80FF80, 0x8080FF, 0xFF80FF, 0xFFFF80, 0x80FFFF, 0x0080FF]

    begin
      require 'gdchart/pie'
    rescue LoadError
      return
    end
    pie = GDChart::Pie.new
    pie.depth = 25
    pie.label_font = GRAPH_TT_FONT
    pie.label_size = GDChart::FONT_SIZE::SMALL
    pie.label_ptsize = 10
    pie.color     = colors
    pie.bg_color  = 0xFFFFFF
    pie.percent_labels = GDChart::Pie::PERCENT_TYPE::BELOW
    pie.image_type     = GDChart::IMAGE_TYPE::PNG


    require 'tempfile'
    file = Tempfile.new('kozuchi_graph', 'tmp')
    file.close
    File.open(file.path, 'w+b') do |f|
      pie.out(300, 200, f, GDChart::Pie::TYPE_3D, values, labels)
    end

    data = nil
    begin
      file.open
      data = file.read
    ensure
      file.close(true)
    end

    send_data(data,
              :filename => 'graph.png',
              :type => 'image/png',
              :disposition => 'inline')
  end
end
