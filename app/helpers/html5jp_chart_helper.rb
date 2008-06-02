module Html5jpChartHelper

  def include_javascript_line_chart
    output = ""
    # 参考　http://www.openspc2.org/userAgent/
    if request.user_agent =~ /MSIE/ && !(request.user_agent =~ /Opera/)
      output.concat(javascript_include_tag '/html5jp/excanvas/excanvas.js')
      output.concat("\n")
    end
    output.concat(javascript_include_tag '/html5jp/graph/line.js')
    output
  end

  def javascript_line_chart(items, options = {}, html_options = {})
    options = {:width => 400, :height => 300, :canvas_id => 'reader_chart'}.merge(options)
    output = content_tag('div',"<canvas width=\"#{options[:width]}\" height=\"#{options[:height]}\" id=\"#{options[:canvas_id]}\"></canvas>", html_options)
    output << "\n"
    output << load_line_chart(items, options)
    output
  end
  
  private
  def load_line_chart(items, options)
    chart_options = options.dup.delete_if{|key, value| [:canvas_id, :width, :height].include?(key) || value.blank?}
    javascript_tag <<EOF
Event.observe(window, "load", function() {
  var lg = new html5jp.graph.line("#{options[:canvas_id]}");
  if( ! lg ) { return; }
  var items = #{items.inspect};
  var params = #{options_to_json(chart_options)};
  lg.draw(items, params);
});
EOF
  end
  
  private
  def options_to_json(options)
    # avoid url encoding of local characters
    options_json = "{" + options.map{|key, value|
      if value.nil?
        formed_value = 'null'
      elsif value =~ /^-?[0-9][0-9]*[\.]?[0-9]*$/ 
        formed_value = value =~ /\./ ? value.to_f : value.to_i
      elsif value.kind_of?(Array)
        formed_value = value.inspect # TODO: 要素の中のnil
      else
        formed_value = value
      end
      "#{key}: #{formed_value}"
    }.join(' , ') + "}"
  end
end