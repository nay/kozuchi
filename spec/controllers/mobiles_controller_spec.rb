require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe WelcomeController do
  fixtures :users
  describe "GET index" do
    describe "AU端末から端末情報が送られてきており、対応する簡単ログイン設定があるとき" do
      before do
        @user = users(:no_mobile_ident_user)
        @user.update_mobile_identity!("01234567890123_xx.ezweb.ne.jp", "KDDI-HI31 UP.Browser/6.2.0.5 (GUI) MMP/2.0")

        request.env["HTTP_X_UP_SUBNO"] = "01234567890123_xx.ezweb.ne.jp"
        request.user_agent = "KDDI-HI31 UP.Browser/6.2.0.5 (GUI) MMP/2.0"
        get :index
      end
      it "ログインした状態となる" do
        assigns[:current_user].should == @user
      end
    end
    describe "AU端末から端末情報が送られてきており、対応する簡単ログイン設定がないとき" do
      before do
        request.env["HTTP_X_UP_SUBNO"] = "01234567890123_xx.ezweb.ne.jp"
        request.user_agent = "KDDI-HI31 UP.Browser/6.2.0.5 (GUI) MMP/2.0"
        get :index
      end
      it "ログインした状態とならない" do
        assigns[:current_user].should be_nil
      end
    end

  end

end
