# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe SessionsController do
  fixtures :users

  describe "create" do
    describe "簡単ログイン" do
      it "簡単ログイン設定がされているとき、簡単ログインができる" do
        pending 'jomobileのコード変換がコントローラスペックに未対応？'
        @user = users(:docomo1_user)
        # TODO: 両方いれないとテストがうまくいかない
        request.user_agent = "DoCoMo/1.0/P506iC/ser00000333339"
        request.env["HTTP_USER_AGENT"] = "DoCoMo/1.0/P506iC/ser00000333339"
        assigns[:current_user] = nil
        post :create, :submit => to_sjis("簡単ログイン")
        request.mobile.ident.should == "00000333339"
        assigns[:current_user].should == @user
        response.should redirect_to(home_path)
      end
    end
  end

end
