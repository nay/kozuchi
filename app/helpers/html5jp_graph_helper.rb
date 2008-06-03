module Html5jpGraphHelper

  # Get javascript include tags for HTML5.JP Graph Libraries.
  #  <%= include_html5jp :line %>
  #  <%= include_html5jp :all %>
  #  <%= include_html5jp :line, :excanvas => false %>
  def include_html5jp(*scripts)
    options = scripts.last.kind_of?(Hash) ? scripts.pop : {}
    options = {:excanvas => true}.merge(options)
    
    scripts = [:line, :circle] if scripts.include?(:all)
    
    includes = scripts.map{|s| javascript_include_tag("html5jp/graph/#{s}.js")}
    includes.insert(0,javascript_include_tag('html5jp/excanvas/excanvas.js')) if options[:excanvas]
    includes.join("\n")
  end

  def html5jp_line_graph(items, options = {}, html_options = {})
    options = {:width => 400, :height => 300, :canvas_id => 'reader_chart'}.merge(options)
    output = load_line_chart(items, options)
    output << "\n"
    output << content_tag('div',"<canvas width=\"#{options[:width]}\" height=\"#{options[:height]}\" id=\"#{options[:canvas_id]}\"></canvas>", html_options)
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
  
  # Don't use to_json avoiding url encoding of local characters.
  def options_to_json(options)
    content = options.map{|key, value| "#{key}: #{to_js_value(value)}"}.join(",\n")
    "{#{content}}"
  end

  def to_js_value(value)
    if value.nil?
      'null'
    elsif value.kind_of?(Array)
      "[#{value.map{|v| array_element_to_js_value(v)}.join(', ')}]"
    else
      value.to_s
    end
  end
  
  def array_element_to_js_value(value)
    if value.nil?
      'null'
    elsif value.kind_of?(Numeric) || value.to_s =~ /^-?[0-9][0-9]*[\.]?[0-9]*$/
      value
    elsif value.kind_of?(Array)
      "[#{value.map{|v| array_element_to_js_value(v)}.join(', ')}]"
    else
      "\"#{value}\""
    end
  end
  
end