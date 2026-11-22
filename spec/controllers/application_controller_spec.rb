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
    shared_examples_for 'ログアウトされ、トップページに戻される' do
      it "ログアウトされ、トップページに戻される" do
        get :index
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq '切り替え元か切り替え先のアカウントが見つからないため、ログアウトしました。'
        expect(session[:user_id]).to be_nil
        expect(session[:original_user_id]).to be_nil
      end
    end

    context "homeさんからシングルログインで切り替えているとき" do
      before { switched_from :home }

      context "切り替え元のhomeさんも切り替え先のtaroさんもいるとき" do
        it "そのまま表示される" do
          get :index
          expect(response).to be_successful
          expect(session[:user_id]).to eq users(:taro).id
        end

        it "ユーザーを読むクエリは、切り替え元と切り替え先の2本だけ" do
          user_queries = []
          callback = ->(*, payload) { user_queries << payload[:sql] if payload[:sql].include?('"users"') }
          ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') { get :index }
          expect(user_queries.size).to eq 2
        end
      end

      context "切り替え元のhomeさんのアカウントが削除されたとき" do
        before { users(:home).destroy }
        it_behaves_like 'ログアウトされ、トップページに戻される'
      end

      context "切り替え先のtaroさんのアカウントが削除されたとき" do
        before { users(:taro).destroy }

        context "「ログイン状態を記憶」の Cookie がないとき" do
          it_behaves_like 'ログアウトされ、トップページに戻される'
        end

        context "homeさんの「ログイン状態を記憶」の Cookie があるとき" do
          before do
            users(:home).remember_me
            request.cookies[:auth_token] = users(:home).remember_token
          end
          it_behaves_like 'ログアウトされ、トップページに戻される'
        end
      end
    end
  end
end
