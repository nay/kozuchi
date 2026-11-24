module ControllerSpecHelper

  # AuthenticatedTestHelperを書き換える
  def login_as(user)
    @current_user = user.kind_of?(Symbol) ? users(user) : user
    @request.session[:user_id] = @current_user.try(:id)
  end

  # シングルログインで user から切り替えている状態にする
  def switched_from(user)
    @request.session[:original_user_id] = users(user).id
  end

  shared_examples_for '切り替え中なので操作できず、ホームに戻される' do
    it "操作できず、ホームに戻される" do
      expect(response).to redirect_to(home_path)
      expect(flash[:alert]).to include('切り替えているあいだは操作できません')
    end
  end

  # ログインしていないときのスペックの記述を簡単にする
  def response_should_be_redirected_without_login(&block)
    describe "ログインしていないとき" do
      before {@request.session[:user_id] = nil}
      before &block
      it_behaves_like 'トップページにリダイレクトされる'
    end
  end

  shared_examples_for 'トップページにリダイレクトされる' do
    it "トップページにリダイレクトされる" do
      expect(response).to redirect_to(root_path)
    end
  end

end
include ControllerSpecHelper

