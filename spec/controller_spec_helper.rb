module ControllerSpecHelper

  # AuthenticatedTestHelperを書き換える
  def login_as(user)
    @current_user = user.kind_of?(Symbol) ? users(user) : user
    @request.session[:user_id] = @current_user.try(:id)
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

