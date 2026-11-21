require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../controller_spec_helper')

describe UsersController, type: :controller do
  fixtures :users, :preferences

  before do
    login_as :taro
  end

  describe "edit" do
    it "成功する" do
      get :edit
      expect(response).to be_successful
    end

    context "homeさんからシングルログインで切り替えているとき" do
      before do
        switched_from :home
        get :edit
      end
      it_behaves_like '切り替え中なので操作できず、ホームに戻される'
    end
  end

  describe "update" do
    context "homeさんからシングルログインで切り替えているとき" do
      before { switched_from :home }
      it "操作できずにホームに戻され、メールアドレスは変わらない" do
        put :update, params: {user: {login: 'taro', email: 'changed@example.com'}}
        expect(response).to redirect_to(home_path)
        expect(flash[:alert]).to include('切り替えているあいだは操作できません')
        expect(@current_user.reload.email).to eq 'taro@kozuchi.net'
      end

      context "プロフィールの画面から送られたとき" do
        before { request.env['HTTP_REFERER'] = edit_user_url }
        it "プロフィールの画面ではなく、ホームに戻される" do
          put :update, params: {user: {login: 'taro', email: 'changed@example.com'}}
          expect(response).to redirect_to(home_path)
        end
      end
    end
  end

  describe "update_password" do
    context "homeさんからシングルログインで切り替えているとき" do
      before do
        switched_from :home
        @current_user.update_password_token
      end

      it "taroさんのパスワード再設定のリンクでパスワードを変えると、taroさんのまま、切り替えは終わる" do
        post :update_password, params: {password_token: @current_user.password_token, password: 'newpassword', password_confirmation: 'newpassword'}
        expect(response).to redirect_to(home_path)
        expect(session[:user_id]).to eq @current_user.id
        expect(session[:original_user_id]).to be_nil
      end
    end
  end

  describe "activate" do
    context "homeさんからシングルログインで切り替えているとき" do
      before { switched_from :home }
      let(:jiro) { User.create!(login: 'jiro', email: 'jiro@example.com', password: 'jiro1234', password_confirmation: 'jiro1234') }

      it "jiroさんの有効化のリンクを開くと、jiroさんになり、切り替えは終わる" do
        get :activate, params: {activation_code: jiro.activation_code}
        expect(response).to redirect_to(home_path)
        expect(session[:user_id]).to eq jiro.id
        expect(session[:original_user_id]).to be_nil
      end
    end
  end

  describe "destroy" do
    context "homeさんからシングルログインで切り替えているとき" do
      before { switched_from :home }
      it "操作できずにホームに戻され、アカウントは削除されない" do
        delete :destroy
        expect(response).to redirect_to(home_path)
        expect(flash[:alert]).to include('切り替えているあいだは操作できません')
        expect(User.find_by(id: @current_user.id)).not_to be_nil
      end
    end
  end
end
