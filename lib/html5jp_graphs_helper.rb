# Html5jpGraphsHelper
module Html5jpGraphsHelper

  # Draw a vertical bar chart using Html5jp vertical bar chart (http://www.html5.jp/library/graph_vbar.html).
  #
  # ex.
  #   <%= vertical_bar_chart [['accesses', 520, 340, 804, 602], ['clicks', 101, 76, 239, 321]] %>
  # 
  # The first argument 'resource' can be one of the following forms.
  # * ['accesses', 520, 340, 804, 602]
  # * [['accesses', 520, 340, 804, 602], ['clicks', 101, 76, 239, 321]]
   # * Any other object which has required methods as follows;
  #   * each - to supply record objects.
  #   * items - If :x option does not exist and your resource object has items method, it is called to get :x. You can change the method name by :items_method option.
  #   * scales - If :y option does not exist and your resource object has scales method, it is called to get :y. You can change the method name by :scales_method option
  #   * max_scale - Would be used as :yMax option if it exists.
  #   * The record object shoud have methods as follows.
  #     * label - Like 'accesses' in the example. You can use other method if you specify :label_method option.
  #     * values - Like [520, 340, 804, 602] in the example. You can use other method if you specify :values_method option.
  #     * color - If :barColors option does not exist and your record object has color method, it is used for :barColors. You can change the method name by :color_method option.
  # Additionaly, the following options are available.
  # * :canvas_id - element id of the canvas. Default is 'line_chart'. Note that all rader charts in one page sould have unique canvas_ids.
  # * :width - The width of the canvas. Default is 400.
  # * :height - The height of the canvas. Default is 300.
  # * All options in http://www.html5.jp/library/graph_vbar.html. ex. 'backgroundColor' or :backgroundColor.
  # And you can use html_options for the top level div.
 def vertical_bar_chart(resource, options = {}, html_options = {})
    options = {:width => 400, :height => 300, :canvas_id => 'vertical_bar_chart'}.merge(options.symbolize_keys)
    output = canvas(options, html_options)
    output << "\n"
    output << vertical_bar_chart_js(resource, options)
  end


  # Draw a radar chart using Html5jp radar chart (http://www.html5.jp/library/graph_radar.html).
  #
  # ex.
  #   <%= radar_chart [['review1', 5, 4, 3], ['review2', 3, 5, 2]], :aCap => ['price', 'style', 'sound'] %>
  # 
  # The first argument 'resource' can be one of the following forms.
  # * ['my review', 1, 2, 3, 4]
  # * [['my review', 1, 2, 3, 4], ['all reviews', 2, 3, 4, 3]]
  # * Any other object which has required methods as follows;
  #   * each - to supply record objects.
  #   * items - If :aCap option does not exist and your resource object has items method, it is called to get :aCap. You can change the method name by :items_method option.
  #   * The record object shoud have methods as follows.
  #     * label - Like 'my review' in the example. You can use other method if you specify :label_method option.
  #     * values - Like [1, 2, 3, 4] in the example. You can use other method if you specify :values_method option.
  #     * color - If :faceColors option does not exist and your record object has color method, it is used for :faceColors. You can change the method name by :color_method option.
  # Additionaly, the following options are available.
  # * :canvas_id - element id of the canvas. Default is 'rader_chart'. Note that all rader charts in one page sould have unique canvas_ids.
  # * :width - The width of the canvas. Default is 400.
  # * :height - The height of the canvas. Default is 300.
  # * All options in http://www.html5.jp/library/graph_radar.html. ex. 'aMax' or :aMax.
  # And you can use html_options for the top level div.
  def radar_chart(resource, options = {}, html_options = {})
    options = {:width => 400, :height => 300, :canvas_id => 'reader_chart'}.merge(options.symbolize_keys)
    output = canvas(options, html_options)
    output << "\n"
    output << rader_chart_js(resource, options)
  end
  
  # Draw a line chart using Html5jp radar chart (http://www.html5.jp/library/graph_line.html).
  #
  # ex.
  #   <%= line_chart [['accesses', 520, 340, 804, 602], ['clicks', 101, 76, 239, 321]] %>
  # 
  # The first argument 'resource' can be one of the following forms.
  # * ['accesses', 520, 340, 804, 602]
  # * [['accesses', 520, 340, 804, 602], ['clicks', 101, 76, 239, 321]]
  # * Any other object which has required methods as follows;
  #   * each - to supply record objects.
  #   * items - If :x option does not exist and your resource object has items method, it is called to get :x. You can change the method name by :items_method option.
  #   * scales - If :y option does not exist and your resource object has scales method, it is called to get :y. You can change the method name by :scales_method option
  #   * max_scale - Would be used as :yMax option if it exists.
  #   * min_scale - Would be used as :yMin option if it exists.
  #   * The record object shoud have methods as follows.
  #     * label - Like 'accesses' in the example. You can use other method if you specify :label_method option.
  #     * values - Like [520, 340, 804, 602] in the example. You can use other method if you specify :values_method option.
  # Additionaly, the following options are available.
  # * :canvas_id - element id of the canvas. Default is 'line_chart'. Note that all rader charts in one page sould have unique canvas_ids.
  # * :width - The width of the canvas. Default is 400.
  # * :height - The height of the canvas. Default is 300.
  # * All options in http://www.html5.jp/library/graph_line.html. ex. 'yMax' or :yMax.
  # And you can use html_options for the top level div.
  def line_chart(resource, options = {}, html_options = {})
    options = {:width => 400, :height => 300, :canvas_id => 'line_chart'}.merge(options.symbolize_keys)
    output = canvas(options, html_options)
    output << "\n"
    output << line_chart_js(resource, options)
  end

  # Draw a pie chart using HTML5jp pie chart (http://www.html5.jp/library/graph_circle.html).
  #
  # ex.
  #   <%= pie_chart([["very good", 400], ["good", 300], ["bad", 100], ["very bad", 300]]) %>
  #
  # The first argument 'resource' can be one of the following forms.
  # * [["very good", 400], ["good", 300], ["bad", 100], ["very bad", 300, "red"]]
  # * Any other object which has required methods as follows;
  #   * each - to supply record objects.
  #   * The record object shoud have methods as follows.
  #     * label - Like 'very good' in the example. You can use other method if you specify :label_method option.
  #     * value - Like 400 in the example. You can use other method if you specify :value_method option.
  #     * color - Like "red" in the example. You can use other method if you specify :color_method option. This is optional.
  # Additionaly, the following options are available.
  # * :canvas_id - element id of the canvas. Default is 'pie_chart'. Note that all rader charts in one page sould have unique canvas_ids.
  # * :width - The width of the canvas. Default is 400.
  # * :height - The height of the canvas. Default is 300.
  # * :sort - If true, sort the records in descending order. Default is false.
  # * All options in http://www.html5.jp/library/graph_circle.html. ex. 'startAngle' or :startAngle.
  # And you can use html_options for the top level div.
  def pie_chart(resource, options = {}, html_options = {})
    options = {:width => 400, :height => 300, :canvas_id => 'pie_chart', :sort => false}.merge(options.symbolize_keys)
    output = canvas(options, html_options)
    output << "\n"
    output << pie_chart_js(resource, options)
  end
  
  private
  
  def canvas(options, html_options)
    content_tag(:div, content_tag(:canvas, '', :width => options[:width], :height => options[:height], :id => options[:canvas_id]), html_options)
  end
  
  def vertical_bar_chart_js(resource, options)
    graph_options = options.dup.delete_if{|key, value| [:canvas_id, :width, :height, :items_method, :scales_method, :max_scale_method, :label_method, :values_method, :color_method].include?(key) || value.blank?}
    options = {:items_method => :items, :scales_method => :scales, :max_scale_method => :max_scale, :label_method => :label, :values_method => :values, :color_method => :color}.merge(options)
    
    if resource.kind_of?(Array) && resource.first.kind_of?(Array)
      records = resource
    elsif resource.kind_of?(Array) && resource.first.kind_of?(String)
      records = [resource]
    else
      records = []
      record_colors = []
      for record in resource
        records << [record.send(options[:label_method])].concat(record.send(options[:values_method]))
        record_colors << record.send(options[:color_method]) if !graph_options[:barColors] && record.respond_to?(options[:color_method])
      end
      graph_options[:x] ||= resource.send(options[:items_method]) if resource.respond_to?(options[:items_method])
      graph_options[:y] ||= resource.send(options[:scales_method]) if resource.respond_to?(options[:scales_method])
      graph_options[:yMax] ||= resource.send(options[:max_scale_method]) if resource.respond_to?(options[:max_scale_method])
      graph_options[:barColors] ||= record_colors unless record_colors.find{|c| c}.blank?
    end
    
    draw("vbar", options[:canvas_id], records, graph_options)
  end
  
  def rader_chart_js(resource, options)
    graph_options = options.dup.delete_if{|key, value| [:canvas_id, :width, :height, :label_method, :values_method, :items_method, :color_method].include?(key) || value.blank?}
    options = {:label_method => :label, :values_method => :values, :items_method => :items, :color_method => :color}.merge(options)

    if resource.kind_of?(Array) && resource.first.kind_of?(Array)
      records = resource
    elsif resource.kind_of?(Array) && resource.first.kind_of?(String)
      records = [resource]
    else
      records = []
      record_colors = []
      for record in resource
        records << [record.send(options[:label_method])].concat(record.send(options[:values_method]))
        record_colors << record.send(options[:color_method]) if !graph_options[:faceColors] && record.respond_to?(options[:color_method])
      end
      graph_options[:aCap] ||= resource.send(options[:items_method]) if resource.respond_to?(options[:items_method])
      graph_options[:faceColors] ||= record_colors unless record_colors.find{|c| c}.blank?
    end

    draw("radar", options[:canvas_id], records, graph_options)
  end

  def line_chart_js(resource, options)
    graph_options = options.dup.delete_if{|key, value| [:canvas_id, :width, :height, :items_method, :scales_method, :max_scale_method, :min_scale_method, :label_method, :values_method].include?(key) || value.blank?}
    options = {:items_method => :items, :scales_method => :scales, :max_scale_method => :max_scale, :min_scale_method => :min_scale, :label_method => :label, :values_method => :values}.merge(options)

    if resource.kind_of?(Array) && resource.first.kind_of?(Array)
      records = resource
    elsif resource.kind_of?(Array) && resource.first.kind_of?(String)
      records = [resource]
    else
      records = []
      for record in resource
        records << [record.send(options[:label_method])].concat(record.send(options[:values_method]))
      end
      graph_options[:x] ||= resource.send(options[:items_method]) if resource.respond_to?(options[:items_method])
      graph_options[:y] ||= resource.send(options[:scales_method]) if resource.respond_to?(options[:scales_method])
      graph_options[:yMax] ||= resource.send(options[:max_scale_method]) if resource.respond_to?(options[:max_scale_method])
      graph_options[:yMin] ||= resource.send(options[:min_scale_method]) if resource.respond_to?(options[:min_scale_method])
    end
    
    draw("line", options[:canvas_id], records, graph_options)
  end

  def pie_chart_js(resource, options)
    graph_options = options.dup.delete_if{|key, value| [:canvas_id, :items, :width, :height, :label_method, :value_method, :color_method, :sort].include?(key) || value.blank?}
    options = {:label_method => :label, :value_method => :value, :color_method => :color}.merge(options)
  
    if resource.kind_of?(Array) && resource.first.kind_of?(Array)
      records = resource
    else
      records = []
      for record in resource
        record_array = [record.send(options[:label_method]), record.send(options[:value_method])]
        record_array << record.send(options[:color_method]) if record.respond_to?(options[:color_method])
        records << record_array
      end
    end
    
    records = records.sort {|r1, r2| r2[1] <=> r1[1]} if options[:sort]
  
    draw("circle", options[:canvas_id], records, graph_options)
  end

  
  def draw(class_name, canvas_id, records, graph_options)
    script = <<-EOS
    var rc = new html5jp.graph.#{class_name}("#{canvas_id}");
    if( ! rc ) { return; }
    var records = #{to_js_value(records)};
    var options = #{options_to_json(graph_options)};
    rc.draw(records, options);
EOS

    javascript_tag <<-EOS
if (jQuery) {
  jQuery(function(){
#{script}
  })
} else {
  Event.observe(window, 'load', function() {
#{script}
  })
}
    EOS
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
