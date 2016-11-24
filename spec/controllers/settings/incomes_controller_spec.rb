# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../controller_spec_helper')

describe Settings::AccountsController, type: :controller do
  self.use_transactional_tests = true
  fixtures :users, :preferences, :accounts
  set_fixture_class :accounts => Account::Base, :preferences => Preferences

  # TODO: 環境が汚れているため記入を削除する
  before do
    Entry::Base.delete_all
    Deal::Base.delete_all
    Pattern::Deal.delete_all
    Pattern::Entry.delete_all
  end

  describe "/incomes" do

    before do
      login_as :taro
    end

    response_should_be_redirected_without_login { get :index, account_type: 'income' }

    describe "index" do
      it "成功する" do
        get :index, account_type: 'income'
        expect(response).to be_success
      end
    end

    describe "create" do
      shared_examples_for 'current_userのincomeが登録される' do
        it "current_userのincomeが登録される" do
          expect(response).to redirect_to(settings_incomes_path)
          income = @current_user.incomes.find_by(name: '追加')
          income.should_not be_nil
          income.sort_key.should == 77
          flash[:errors].should be_nil
        end
      end
      context "正しいパラメータ" do
        before do
          post :create, :account => {:name => '追加', :sort_key => 77}, account_type: 'income'
        end
        it_should_behave_like 'current_userのincomeが登録される'
      end
      context "別のuser_idを指定" do
        before do
          post :create, :account => {:name => '追加', :sort_key => 77, :user_id => :hanako.to_id}, account_type: 'income'
        end
        it_should_behave_like 'current_userのincomeが登録される'
      end
      context "重複した名前" do
        before do
          post :create, :account => {:name => '給料', :sort_key => 77}, account_type: 'income'
        end
        it "エラーメッセージ" do
          expect(response).to be_success
          assigns(:account).errors.should_not be_empty
        end
      end
    end

    describe "update_all" do
      before do
        @current_values = {}
        @current_user.incomes.each{|a| @current_values[a.id.to_s] = {:name => a.name, :sort_key => a.sort_key}}
      end
      it "成功する" do
        @current_values[:taro_salary.to_id.to_s][:name] = "きゅうりょう"
        put :update_all, :account => @current_values, account_type: 'income'
        expect(response).to redirect_to(settings_incomes_path)
        income = @current_user.incomes.find_by(name: 'きゅうりょう')
        income.should_not be_nil
        flash[:errors].should be_nil
      end
      it "空の口座名をいれるとエラーメッセージ" do
        @current_values[:taro_salary.to_id.to_s][:name] = ""
        put :update_all, :account => @current_values, account_type: 'income'
        expect(response).to be_success
        @current_user.incomes.find_by(name: '給料').should_not be_nil
        assigns(:accounts).any?{|a| !a.errors.empty?}.should be_truthy
      end
      it "他人の口座の情報を混ぜると例外" do
        @current_values[:hanako_salary.to_id.to_s] = {:name => '花子の給料改'}
        lambda{put :update_all, :account => @current_values, account_type: 'income'}.should raise_error(ActiveRecord::RecordNotFound)
      end
    end

    describe "destroy" do
      it "成功する" do
        delete :destroy, :id => :taro_salary.to_id, account_type: 'income'
        expect(response).to redirect_to(settings_incomes_path)
        flash[:errors].should be_nil
        Account::Base.find_by(id: :taro_salary.to_id).should be_nil
      end
      it "他人の口座を指定できない" do
        lambda{delete :destroy, :id => :hanako_salary.to_id, account_type: 'income'}.should raise_error(ActiveRecord::RecordNotFound)
      end
      it "使っている口座は削除できない" do
        @current_user.general_deals.create!(:debtor_entries_attributes => [{:amount => 100, :account_id => :taro_cache.to_id}],
          :creditor_entries_attributes => [{:amount => -100, :account_id => :taro_salary.to_id}],
          :date => Date.today
          )
        delete :destroy, :id => :taro_salary.to_id, account_type: 'income'
        expect(response).to redirect_to(settings_incomes_path)
        flash[:errors].should_not be_nil
        @current_user.incomes.find_by(id: :taro_salary.to_id).should_not be_nil
      end
    end
  end
end
