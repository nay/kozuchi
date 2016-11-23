# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../controller_spec_helper')

describe WelcomeController do
  fixtures :users
  describe "GET index" do
    describe "pc" do
      describe "ログインしていないとき" do
        before do
          get :index
        end
        it "成功する" do
          response.should be_success
        end
      end
      describe "ログインしているとき" do
        before do
          login_as :taro
          get :index
        end
        it "成功する" do
          response.should be_success
        end
      end
    end
  end

end
