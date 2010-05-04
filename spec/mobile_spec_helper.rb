# Docomo mova で機種情報なしでアクセスするための事前準備
module MobileSpecHelper
  def set_docomo_mova_to(request)
    request.user_agent = "DoCoMo/1.0/P506iC"
    request.env["HTTP_USER_AGENT"] = "DoCoMo/1.0/P506iC"
  end

  def set_docomo_foma_to(request)
    request.env["HTTP_X_DCMGUID"] = "0123456"
    request.user_agent = "DoCoMo/2.0 SH02A"
  end

  def set_au_to(request)
    request.env["HTTP_X_UP_SUBNO"] = "01234567890123_xx.ezweb.ne.jp"
    request.user_agent = "KDDI-HI31 UP.Browser/6.2.0.5 (GUI) MMP/2.0"
  end
end
include MobileSpecHelper
