require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../controller_spec_helper')

describe UsersController, type: :controller do
  fixtures :users, :preferences

  before do
    login_as :taro
  end

  describe "edit" do
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

  describe "update_password" do
    context "homeさんからシングルログインで切り替えているとき" do
      before { switched_from :home }

      context "taroさんがパスワード再設定を申し込んでいるとき" do
        before { @current_user.update_password_token }

        shared_examples_for 'パスワードが変わり、taroさんのまま、切り替えは終わる' do
          it "パスワードが変わり、taroさんのまま、切り替えは終わる" do
            post :update_password, params: {password_token: @current_user.password_token, password: 'newpassword', password_confirmation: 'newpassword'}
            expect(response).to redirect_to(home_path)
            expect(User.authenticate('taro', 'newpassword')).to eq @current_user
            expect(session[:user_id]).to eq @current_user.id
            expect(session[:original_user_id]).to be_nil
          end
        end

        context "どちらのアカウントもあるとき" do
          it_behaves_like 'パスワードが変わり、taroさんのまま、切り替えは終わる'
        end

        context "切り替え元のhomeさんのアカウントが削除されているとき" do
          before { users(:home).destroy }
          it_behaves_like 'パスワードが変わり、taroさんのまま、切り替えは終わる'
        end
      end
    end

    context "無効なパスワード再設定のリンクのとき" do
      before { post :update_password, params: {password_token: 'invalid', password: 'newpassword', password_confirmation: 'newpassword'} }

      it "申し込み直すよう伝えて、パスワードを忘れたときの画面に戻される" do
        expect(response).to redirect_to(forgot_password_path)
        expect(flash[:alert]).to eq 'このパスワード変更のお申し込みは無効になっています。恐れ入りますが、あらためてお申し込みください。'
      end
    end
  end

  describe "activate" do
    context "homeさんからシングルログインで切り替えているとき" do
      before { switched_from :home }

      context "jiroさんの有効化のリンクがあるとき" do
        let(:jiro) { User.create!(login: 'jiro', email: 'jiro@example.com', password: 'jiro1234', password_confirmation: 'jiro1234') }

        shared_examples_for 'jiroさんが有効になってjiroさんになり、切り替えは終わる' do
          it "jiroさんが有効になってjiroさんになり、切り替えは終わる" do
            get :activate, params: {activation_code: jiro.activation_code}
            expect(response).to redirect_to(home_path)
            expect(jiro.reload).to be_active
            expect(session[:user_id]).to eq jiro.id
            expect(session[:original_user_id]).to be_nil
          end
        end

        context "どちらのアカウントもあるとき" do
          it_behaves_like 'jiroさんが有効になってjiroさんになり、切り替えは終わる'
        end

        context "切り替え元のhomeさんのアカウントが削除されているとき" do
          before { users(:home).destroy }
          it_behaves_like 'jiroさんが有効になってjiroさんになり、切り替えは終わる'
        end
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
