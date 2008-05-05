module GraphHelper

# HTML5.JP glaph_circle を用いて円グラフを描画する
  def pie_graph(resources, percentage_method, name_method, value_method = nil, total_value = nil, id = "graph")
    data = {}
    begin
      for r in resources
        if percentage_method
          percentage = r.method(percentage_method).call
        else
          percentage = total_value != 0 ? (r.method(value_method).call * 100.0 / total_value).round : 0
        end
        next if percentage == 100 || percentage == 0
        data[r.method(name_method).call] = percentage.to_s
      end

      if data.size > 1
#        url = url_for(:controller=>'graph', :action=>'pie', :labels=>labels, :values=>values)
#        return '<img width="300" height="200" src="' + url + '" />'
        return render_javascript_pie( id, data )
      else
        return '<span>グラフは２つ以上の項目があるときに表示されます。</span>'
      end
    rescue => err
      return "<span>エラーのためグラフを表示できません。<br />#{err}<br />#{err.backtrace}</span>"
    end
  end
  
  private
  def render_javascript_pie id, data
    s = javascript_tag <<-EOS
Event.observe(window, 'load', function () {
	var cg = new html5jp.graph.circle("#{id}");
	if( ! cg ) { return; }
	var items = [
        #{ to_items( data ) }
	];
	cg.draw(items);
}, false);
    EOS
    s << %Q(<div><canvas width="300" height="200" id="#{id}"></canvas></div>)
  end
  
  def to_items( data )
    r = ''
    data.each do |key, value|
      r << %Q(["#{key}", #{value}],\n)
    end
    r.chomp!(",\n")
  end

end
