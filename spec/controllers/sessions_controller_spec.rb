require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../controller_spec_helper')

describe SessionsController, type: :controller do
  fixtures :users, :preferences

  describe "update" do
    before do
      login_as :taro
      @current_user.single_logins.create!(login: 'hanako', password: 'hanako')
    end

    context "シングルログインで切り替えていないとき" do
      it "シングルログイン設定のあるhanakoさんに切り替わる" do
        put :update, params: {login: 'hanako'}
        expect(response).to redirect_to(home_path)
        expect(session[:user_id]).to eq users(:hanako).id
        expect(session[:original_user_id]).to eq users(:taro).id
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

      it "今のtaroさんのシングルログイン設定にあるhanakoさんを指定すると、操作できずにホームに戻され、切り替わらない" do
        put :update, params: {login: 'hanako'}
        expect(response).to redirect_to(home_path)
        expect(flash[:alert]).to include('切り替えているあいだは操作できません')
        expect(session[:user_id]).to eq users(:taro).id
        expect(session[:original_user_id]).to eq users(:home).id
      end
    end
  end
end
