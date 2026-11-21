require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../controller_spec_helper')

describe ApplicationController, type: :controller do
  fixtures :users, :preferences

  controller do
    def index
      head :ok
    end
  end

  before do
    login_as :taro
  end

  describe "シングルログインの切り替え元と切り替え先のユーザーの確認" do
    context "homeさんからシングルログインで切り替えているとき" do
      before { switched_from :home }

      it "そのまま表示される" do
        get :index
        expect(response).to be_successful
        expect(session[:user_id]).to eq users(:taro).id
      end
    end

    shared_examples_for 'ログアウトされ、トップページに戻される' do
      it "ログアウトされ、トップページに戻される" do
        get :index
        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to eq '切り替え元か切り替え先のアカウントが見つからないため、ログアウトしました。'
        expect(session[:user_id]).to be_nil
        expect(session[:original_user_id]).to be_nil
      end
    end

    context "homeさんからシングルログインで切り替えていて、切り替え元のhomeさんのアカウントが削除されたとき" do
      before do
        switched_from :home
        users(:home).destroy
      end
      it_behaves_like 'ログアウトされ、トップページに戻される'
    end

    context "homeさんからシングルログインで切り替えていて、切り替え先のtaroさんのアカウントが削除されたとき" do
      before do
        switched_from :home
        users(:taro).destroy
      end
      it_behaves_like 'ログアウトされ、トップページに戻される'
    end
  end
end
