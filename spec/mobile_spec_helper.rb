# Docomo mova で機種情報なしでアクセスするための事前準備
def set_docomo_mova_to(request)
  request.user_agent = "DoCoMo/1.0/P506iC"
  request.env["HTTP_USER_AGENT"] = "DoCoMo/1.0/P506iC"
end

def set_docomo_foma_to(request)
  request.env["HTTP_X_DCMGUID"] = "0123456"
  request.user_agent = "DoCoMo/2.0 SH02A"
end