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
