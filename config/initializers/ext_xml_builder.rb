#require 'builder/xmlmarkup'



# 高速化のため＆XMLの利用者がUTF8で日本語を表示できる環境であることを想定するため、
# （＆、もしかするとWindows環境で不正なXMLになることを避けるため）
# _escape(text)でto_xsを行わないようにする
module Builder
  class XmlMarkup < XmlBase
    private
    def _escape(text)
      text
    end

  end
end
