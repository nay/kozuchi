require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../controller_spec_helper')

describe SessionsController, type: :controller do
  fixtures :users, :preferences

  describe "create" do
    before { login_as :taro }

    context "homeさんからシングルログインで切り替えているとき" do
      before { switched_from :home }

      context "どちらのアカウントもあるとき" do
        context "taroさんでログインし直したとき" do
          before { post :create, params: {login: 'taro', password: 'taro'} }

          it "taroさんのまま、切り替えは終わる" do
            expect(response).to redirect_to(home_path)
            expect(session[:user_id]).to eq users(:taro).id
            expect(session[:original_user_id]).to be_nil
          end
        end

        context "ログインに失敗したとき" do
          before { post :create, params: {login: 'taro', password: 'wrong'} }

          it "ログアウトされ、切り替えも終わる" do
            expect(response).to redirect_to(root_path)
            expect(flash[:alert]).to eq 'ログインに失敗しました。'
            expect(session[:user_id]).to be_nil
            expect(session[:original_user_id]).to be_nil
          end
        end
      end

      context "切り替え先のtaroさんのアカウントが削除されているとき" do
        before { users(:taro).destroy }

        context "ほかのユーザーでログインしたとき" do
          before { post :create, params: {login: 'no_mobile_ident_user', password: 'test'} }

          it "そのユーザーになり、切り替えは終わる" do
            expect(response).to redirect_to(home_path)
            expect(session[:user_id]).to eq users(:no_mobile_ident_user).id
            expect(session[:original_user_id]).to be_nil
          end
        end
      end
    end
  end

  describe "destroy" do
    shared_examples_for 'ログアウトされる' do
      it "ログアウトされる" do
        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to eq 'ログアウトしました。'
        expect(session[:user_id]).to be_nil
        expect(session[:original_user_id]).to be_nil
      end
    end

    context "taroさんでログインしていて、homeさんもtaroさんも「ログイン状態を記憶」しているとき" do
      before do
        login_as :taro
        users(:home).remember_me
        users(:taro).remember_me
      end

      context "taroさんがシングルログインで切り替えていないとき" do
        before { delete :destroy }

        it_behaves_like 'ログアウトされる'
        it "taroさんの記憶が消える" do
          expect(users(:taro).reload.remember_token).to be_nil
        end
      end

      context "homeさんからtaroさんにシングルログインで切り替えているとき" do
        before { switched_from :home }

        context "どちらのアカウントもあるとき" do
          before { delete :destroy }

          it_behaves_like 'ログアウトされる'
          it "切り替え元のhomeさんの記憶だけが消える" do
            expect(users(:home).reload.remember_token).to be_nil
            expect(users(:taro).reload.remember_token).not_to be_nil
          end
        end

        context "切り替え元のhomeさんのアカウントが削除されているとき" do
          before do
            users(:home).destroy
            delete :destroy
          end

          it_behaves_like 'ログアウトされる'
          it "切り替え先のtaroさんの記憶は消えない" do
            expect(users(:taro).reload.remember_token).not_to be_nil
          end
        end

        context "切り替え先のtaroさんのアカウントが削除されているとき" do
          before do
            users(:taro).destroy
            delete :destroy
          end

          it_behaves_like 'ログアウトされる'
          it "切り替え元のhomeさんの記憶が消える" do
            expect(users(:home).reload.remember_token).to be_nil
          end
        end
      end
    end
  end

  describe "update" do
    before { login_as :taro }

    context "シングルログインで切り替えていないとき" do
      context "taroさんにhanakoさんへのシングルログイン設定があり、hanakoさんを指定したとき" do
        before do
          @current_user.single_logins.create!(login: 'hanako', password: 'hanako')
          put :update, params: {login: 'hanako'}
        end

        it "hanakoさんに切り替わる" do
          expect(response).to redirect_to(home_path)
          expect(session[:user_id]).to eq users(:hanako).id
          expect(session[:original_user_id]).to eq users(:taro).id
        end
      end
    end

    context "homeさんからシングルログインで切り替えているとき" do
      before { switched_from :home }

      context "元のhomeさんを指定したとき" do
        before { put :update, params: {login: 'home'} }

        it "homeさんに戻る" do
          expect(response).to redirect_to(home_path)
          expect(session[:user_id]).to eq users(:home).id
          expect(session[:original_user_id]).to be_nil
        end
      end

      context "今のtaroさんを指定したとき" do
        before { put :update, params: {login: 'taro'} }

        it "taroさんのまま変わらない" do
          expect(response).to redirect_to(home_path)
          expect(flash[:notice]).to eq 'taroさんの家計簿に移動しました。'
          expect(flash[:alert]).to be_nil
          expect(session[:user_id]).to eq users(:taro).id
          expect(session[:original_user_id]).to eq users(:home).id
        end
      end

      context "taroさんにhanakoさんへのシングルログイン設定があり、hanakoさんを指定したとき" do
        before do
          @current_user.single_logins.create!(login: 'hanako', password: 'hanako')
          put :update, params: {login: 'hanako'}
        end

        it "操作できずにホームに戻され、切り替わらない" do
          expect(response).to redirect_to(home_path)
          expect(flash[:alert]).to include('切り替えているあいだは操作できません')
          expect(session[:user_id]).to eq users(:taro).id
          expect(session[:original_user_id]).to eq users(:home).id
        end
      end
    end
  end
end
