require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../controller_spec_helper')

describe Settings::SingleLoginsController, type: :controller do
  fixtures :users, :friend_requests, :friend_permissions

  before do
    login_as :taro
  end

  response_should_be_redirected_without_login { get :index }

  describe "index" do
    context "シングルログインで切り替えていないとき" do
      it "成功する" do
        get :index
        expect(response).to be_successful
      end
    end

    context "homeさんからシングルログインで切り替えているとき" do
      before do
        switched_from :home
        get :index
      end
      it_behaves_like '切り替え中なので操作できず、ホームに戻される'
    end
  end

  describe "create" do
    it "成功する" do
      post :create, params: {:single_login => {:login => 'hanako', :password => 'hanako'}}
      expect(response).to redirect_to(settings_single_logins_path)
      expect(flash[:alert]).to be_nil
      expect(@current_user.single_logins.find_by(login: 'hanako')).not_to be_nil
    end
    it "パスワードが違うと成功しない" do
      post :create, params: {:single_login => {:login => 'hanako', :password => 'hanako2'}}
      expect(response).to be_successful
      expect(assigns(:single_login).errors).not_to be_empty
      expect(@current_user.single_logins.find_by(login: 'hanako')).to be_nil
    end

    context "homeさんからシングルログインで切り替えているとき" do
      before { switched_from :home }
      it "操作できずにホームに戻され、設定は追加されない" do
        post :create, params: {:single_login => {:login => 'hanako', :password => 'hanako'}}
        expect(response).to redirect_to(home_path)
        expect(flash[:alert]).to include('切り替えているあいだは操作できません')
        expect(@current_user.single_logins.find_by(login: 'hanako')).to be_nil
      end
    end
  end

  describe "destroy" do
    before do
      @single_login = @current_user.single_logins.create!(login: 'hanako', password: 'hanako')
    end

    context "homeさんからシングルログインで切り替えているとき" do
      before { switched_from :home }
      it "操作できずにホームに戻され、設定は残る" do
        delete :destroy, params: {id: @single_login.id}
        expect(response).to redirect_to(home_path)
        expect(flash[:alert]).to include('切り替えているあいだは操作できません')
        expect(SingleLogin.find_by(id: @single_login.id)).not_to be_nil
      end
    end
  end

end
