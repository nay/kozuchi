require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../controller_spec_helper')

describe WelcomeController do
  fixtures :users
  describe "GET index" do
    describe "pc" do
      describe "ログインしていないとき" do
        before do
          get :index
        end
        it "成功する" do
          response.should be_success
        end
      end
      describe "ログインしているとき" do
        before do
          login_as :taro
          get :index
        end
        it "成功する" do
          response.should be_success
        end
      end
    end

    describe "mobile" do
      describe "AU" do
        describe "簡単ログイン設定があるとき" do
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
        describe "簡単ログイン設定がないとき" do
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

      describe "DoCoMo iモードID" do
        describe "簡単ログイン設定があるとき" do
          before do
            @user = users(:no_mobile_ident_user)
            @user.update_mobile_identity!("0123456", "DoCoMo/2.0 SH02A")

            request.env["HTTP_X_DCMGUID"] = "0123456"
            request.user_agent = "DoCoMo/2.0 SH02A"
            get :index
          end
          it "ログインした状態となる" do
            assigns[:current_user].should == @user
          end
        end
        describe "簡単ログイン設定がないとき" do
          before do
            request.env["HTTP_X_DCMGUID"] = "0123456"
            request.user_agent = "DoCoMo/2.0 SH02A"
            get :index
          end
          it "ログインした状態とならない" do
            assigns[:current_user].should be_nil
          end
        end
      end
    end
  end

end
