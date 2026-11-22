require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../controller_spec_helper')

describe SessionsController, type: :controller do
  fixtures :users, :preferences

  describe "create" do
    before { login_as :taro }

    context "homeさんからシングルログインで切り替えているとき" do
      before { switched_from :home }

      it "taroさんでログインし直すと、taroさんのまま、切り替えは終わる" do
        post :create, params: {login: 'taro', password: 'taro'}
        expect(response).to redirect_to(home_path)
        expect(session[:user_id]).to eq users(:taro).id
        expect(session[:original_user_id]).to be_nil
      end

      it "ログインに失敗すると、ログアウトされ、切り替えも終わる" do
        post :create, params: {login: 'taro', password: 'wrong'}
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq 'ログインに失敗しました。'
        expect(session[:user_id]).to be_nil
        expect(session[:original_user_id]).to be_nil
      end

      context "切り替え先のtaroさんのアカウントが削除されているとき" do
        before { users(:taro).destroy }

        it "ほかのユーザーでログインすると、そのユーザーになり、切り替えは終わる" do
          post :create, params: {login: 'no_mobile_ident_user', password: 'test'}
          expect(response).to redirect_to(home_path)
          expect(session[:user_id]).to eq users(:no_mobile_ident_user).id
          expect(session[:original_user_id]).to be_nil
        end
      end
    end
  end

  describe "destroy" do
    before { login_as :taro }

    context "homeさんからシングルログインで切り替えているとき" do
      before { switched_from :home }

      context "切り替え先のtaroさんのアカウントが削除されているとき" do
        before { users(:taro).destroy }

        it "ログアウトされる" do
          delete :destroy
          expect(response).to redirect_to(root_path)
          expect(flash[:notice]).to eq 'ログアウトしました。'
          expect(session[:user_id]).to be_nil
          expect(session[:original_user_id]).to be_nil
        end
      end
    end
  end

  describe "update" do
    before { login_as :taro }

    context "シングルログインで切り替えていないとき" do
      context "taroさんにhanakoさんへのシングルログイン設定があるとき" do
        before { @current_user.single_logins.create!(login: 'hanako', password: 'hanako') }

        it "hanakoさんを指定すると、hanakoさんに切り替わる" do
          put :update, params: {login: 'hanako'}
          expect(response).to redirect_to(home_path)
          expect(session[:user_id]).to eq users(:hanako).id
          expect(session[:original_user_id]).to eq users(:taro).id
        end
      end
    end

    context "homeさんからシングルログインで切り替えているとき" do
      before { switched_from :home }

      it "元のhomeさんを指定すると、homeさんに戻る" do
        put :update, params: {login: 'home'}
        expect(response).to redirect_to(home_path)
        expect(session[:user_id]).to eq users(:home).id
        expect(session[:original_user_id]).to be_nil
      end

      it "今のtaroさんを指定すると、taroさんのまま変わらない" do
        put :update, params: {login: 'taro'}
        expect(response).to redirect_to(home_path)
        expect(session[:user_id]).to eq users(:taro).id
        expect(session[:original_user_id]).to eq users(:home).id
      end

      context "taroさんにhanakoさんへのシングルログイン設定があるとき" do
        before { @current_user.single_logins.create!(login: 'hanako', password: 'hanako') }

        it "hanakoさんを指定すると、操作できずにホームに戻され、切り替わらない" do
          put :update, params: {login: 'hanako'}
          expect(response).to redirect_to(home_path)
          expect(flash[:alert]).to include('切り替えているあいだは操作できません')
          expect(session[:user_id]).to eq users(:taro).id
          expect(session[:original_user_id]).to eq users(:home).id
        end
      end
    end
  end
end
