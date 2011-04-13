module StructureHelper

  def with_label(label, inner_content = '', &block)
    if block_given?
      inner_content = capture(&block)
    end
    content = <<EOS
    <tr>
      <th>
        <label>#{label}</label>
      </th>
      <td>#{inner_content}</td>
    </tr>
EOS
    content.html_safe
  end

end