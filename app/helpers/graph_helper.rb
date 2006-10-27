module GraphHelper

# 円グラフのためのURLを表示する
  def pie_graph(resource_array, percentage_method, name_method, value_method = nil, total_value = nil)
    labels = ''
    values = ''
    begin
      for r in resource_array
        if percentage_method
          percentage = r.method(percentage_method).call
        else
          percentage = total_value != 0 ? (r.method(value_method).call * 100.0 / total_value).round : 0
        end
        next if percentage == 100 || percentage == 0
        values += percentage.to_s + ','
        labels += r.method(name_method).call + ','
      end

      if labels.count(',') > 1
        url = url_for(:controller=>'graph', :action=>'pie', :labels=>labels, :values=>values)
        return '<img width="300" height="200" src="' + url + '" />'
      else
        return '<span>グラフは２つ以上の項目があるときに表示されます。</span>'
      end
    rescue => err
      return "<span>エラーのためグラフを表示できません。<br />#{err}<br />#{err.backtrace}</span>"
    end
  end

end
