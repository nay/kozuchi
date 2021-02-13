module UsabilityHelper
  
  # ロード時のフォーカスを指定します
  def focus_on(element_id)
    javascript_tag <<EOS
window.onload = function() {
  document.getElementById("#{element_id}").focus();
}
EOS
  end
  
end