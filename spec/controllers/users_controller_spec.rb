require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../controller_spec_helper')

describe UsersController, type: :controller do
  fixtures :users, :preferences

  let(:jiro) { User.create!(login: 'jiro', email: 'jiro@example.com', password: 'jiro1234', password_confirmation: 'jiro1234') } # 有効にしていないユーザー

  shared_examples_for 'ログイン中なので利用できず、ホームに戻される' do
    it "利用できず、ホームに戻される" do
      expect(response).to redirect_to(home_path)
      expect(flash[:alert]).to eq 'ログインしているあいだは利用できません。ログアウトしてから操作してください。'
    end
  end

  describe "edit" do
    before { login_as :taro }

    context "シングルログインで切り替えていないとき" do
      it "プロフィールの画面が表示される" do
        get :edit
        expect(response).to be_successful
      end
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
    before { login_as :taro }

    context "homeさんからシングルログインで切り替えているとき" do
      before do
        switched_from :home
        request.env['HTTP_REFERER'] = edit_user_url # プロフィールの画面から来たリクエストにする
      end
      it "操作できずに、元のプロフィールの画面ではなくホームに戻され、メールアドレスは変わらない" do
        put :update, params: {user: {login: 'taro', email: 'changed@example.com'}}
        expect(response).to redirect_to(home_path)
        expect(flash[:alert]).to include('切り替えているあいだは操作できません')
        expect(@current_user.reload.email).to eq 'taro@kozuchi.net'
      end
    end
  end

  describe "new" do
    context "ログインしているとき" do
      before do
        login_as :taro
        get :new
      end
      it_behaves_like 'ログイン中なので利用できず、ホームに戻される'
    end
  end

  describe "create" do
    context "ログインしているとき" do
      before do
        login_as :taro
        post :create, params: {user: {login: 'jiro', email: 'jiro@example.com', password: 'jiro1234', password_confirmation: 'jiro1234'}}
      end
      it_behaves_like 'ログイン中なので利用できず、ホームに戻される'
      it "ユーザーは登録されない" do
        expect(User.find_by(login: 'jiro')).to be_nil
      end
    end
  end

  describe "forgot_password" do
    context "ログインしているとき" do
      before do
        login_as :taro
        get :forgot_password
      end
      it_behaves_like 'ログイン中なので利用できず、ホームに戻される'
    end
  end

  describe "deliver_password_notification" do
    context "ログインしているとき" do
      before do
        login_as :taro
        post :deliver_password_notification, params: {email: 'taro@kozuchi.net'}
      end
      it_behaves_like 'ログイン中なので利用できず、ホームに戻される'
    end
  end

  describe "edit_password" do
    context "taroさんがパスワード再設定を申し込んでいるとき" do
      before { users(:taro).update_password_token }

      context "ログインしているとき" do
        before do
          login_as :taro
          get :edit_password, params: {password_token: users(:taro).password_token}
        end
        it_behaves_like 'ログイン中なので利用できず、ホームに戻される'
      end
    end
  end

  describe "update_password" do
    context "taroさんがパスワード再設定を申し込んでいるとき" do
      before { users(:taro).update_password_token }

      context "ログインしていないとき" do
        before { post :update_password, params: {password_token: users(:taro).password_token, password: 'newpassword', password_confirmation: 'newpassword'} }

        it "パスワードが変わり、taroさんでログインする" do
          expect(response).to redirect_to(home_path)
          expect(User.authenticate('taro', 'newpassword')).to eq users(:taro)
          expect(session[:user_id]).to eq users(:taro).id
        end
      end

      context "ログインしているとき" do
        before do
          login_as :taro
          post :update_password, params: {password_token: users(:taro).password_token, password: 'newpassword', password_confirmation: 'newpassword'}
        end
        it_behaves_like 'ログイン中なので利用できず、ホームに戻される'
        it "パスワードは変わらない" do
          expect(User.authenticate('taro', 'newpassword')).to be_nil
        end
      end
    end

    context "無効なパスワード再設定のリンクのとき" do
      context "ログインしていないとき" do
        before { post :update_password, params: {password_token: 'invalid', password: 'newpassword', password_confirmation: 'newpassword'} }

        it "申し込み直すよう伝えて、パスワードを忘れたときの画面に戻される" do
          expect(response).to redirect_to(forgot_password_path)
          expect(flash[:alert]).to eq 'このパスワード変更のお申し込みは無効になっています。恐れ入りますが、あらためてお申し込みください。'
        end
      end
    end
  end

  describe "activate" do
    context "jiroさんの有効化のリンクがあるとき" do
      context "ログインしていないとき" do
        before { get :activate, params: {activation_code: jiro.activation_code} }

        it "jiroさんが有効になり、jiroさんでログインする" do
          expect(response).to redirect_to(home_path)
          expect(jiro.reload).to be_active
          expect(session[:user_id]).to eq jiro.id
        end
      end

      context "taroさんでログインしているとき" do
        before do
          login_as :taro
          get :activate, params: {activation_code: jiro.activation_code}
        end
        it_behaves_like 'ログイン中なので利用できず、ホームに戻される'
        it "jiroさんは有効にならない" do
          expect(jiro.reload).not_to be_active
        end
      end
    end
  end

  describe "activate_login_engine" do
    context "jiroさんの有効化のリンクがあるとき" do
      context "taroさんでログインしているとき" do
        before do
          login_as :taro
          get :activate_login_engine, params: {key: jiro.activation_code}
        end
        it_behaves_like 'ログイン中なので利用できず、ホームに戻される'
      end
    end
  end

  describe "destroy" do
    before { login_as :taro }

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
