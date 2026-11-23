require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../controller_spec_helper')

describe ApplicationController, type: :controller do
  fixtures :users, :preferences

  controller do
    skip_before_action :login_required, only: :new

    def index
      head :ok
    end

    def new # 同じリクエストの中で今のユーザーを2回読み、それぞれのログインIDを返す
      render plain: [current_user, current_user].map { |user| user&.login }.inspect
    end
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

    context "homeさんからtaroさんにシングルログインで切り替えているとき" do
      before do
        login_as :taro
        switched_from :home
      end

      context "切り替え元のhomeさんも切り替え先のtaroさんもいるとき" do
        it "そのまま表示される" do
          get :index
          expect(response).to be_successful
          expect(session[:user_id]).to eq users(:taro).id
        end

        it "ユーザーを読むクエリは、切り替え元と切り替え先の2本だけ発行する" do
          user_queries = []
          callback = ->(*, payload) { user_queries << payload[:sql] if payload[:sql].include?('"users"') }
          ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') { get :index }
          expect(user_queries.size).to eq 2
        end
      end

      context "切り替え元のhomeさんのアカウントが削除されているとき" do
        before { users(:home).destroy }
        it_behaves_like 'ログアウトされ、トップページに戻される'
      end

      context "切り替え先のtaroさんのアカウントが削除されているとき" do
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

          it "Cookie も消される" do
            get :index
            expect(cookies[:auth_token]).to be_nil
          end
        end
      end
    end
  end

  describe "今のユーザー" do
    context "セッションにユーザーがないとき" do
      context "homeさんの「ログイン状態を記憶」の Cookie があるとき" do
        before do
          users(:home).remember_me
          request.cookies[:auth_token] = users(:home).remember_token
        end

        it "homeさんでログインする" do
          get :index
          expect(response).to be_successful
          expect(session[:user_id]).to eq users(:home).id
        end
      end

      context "homeさんの「ログイン状態を記憶」の Cookie が期限切れのとき" do
        before do
          users(:home).remember_me_until(1.day.ago)
          request.cookies[:auth_token] = users(:home).remember_token
        end

        it "ログインせず、トップページに戻される" do
          get :index
          expect(response).to redirect_to(root_path)
          expect(session[:user_id]).to be_nil
        end
      end

      context "Basic 認証でtaroさんのログインIDとパスワードを送ったとき" do
        before { request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials('taro', 'taro') }

        it "taroさんでログインする" do
          get :index
          expect(response).to be_successful
          expect(session[:user_id]).to eq users(:taro).id
        end
      end
    end

    context "セッションのtaroさんのアカウントが削除されているとき" do
      before do
        login_as :taro
        users(:taro).destroy
      end

      context "homeさんの「ログイン状態を記憶」の Cookie があるとき" do
        before do
          users(:home).remember_me
          request.cookies[:auth_token] = users(:home).remember_token
        end

        it "同じリクエストの中で何回読んでも、ログインしていない" do
          get :new
          expect(response.body).to eq [nil, nil].inspect
        end
      end
    end
  end
end
