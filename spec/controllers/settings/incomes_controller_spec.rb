require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../controller_spec_helper')

describe Settings::AccountsController, type: :controller do
  self.use_transactional_tests = true
  fixtures :users, :preferences, :accounts

  describe "/incomes" do

    before do
      login_as :taro
    end

    response_should_be_redirected_without_login { get :index, params: {account_type: 'income'} }

    describe "index" do
      it "成功する" do
        get :index, params: {account_type: 'income'}
        expect(response).to be_successful
      end
    end

    describe "create" do
      shared_examples_for 'current_userのincomeが登録される' do
        it "current_userのincomeが登録される" do
          expect(response).to redirect_to(settings_incomes_path)
          income = @current_user.incomes.find_by(name: '追加')
          expect(income).not_to be_nil
          expect(income.sort_key).to eq 77
          expect(flash[:errors]).to be_nil
        end
      end
      context "正しいパラメータ" do
        before do
          post :create, params: {:account => {:name => '追加', :sort_key => 77}, account_type: 'income'}
        end
        it_behaves_like 'current_userのincomeが登録される'
      end
      context "別のuser_idを指定" do
        before do
          post :create, params: {:account => {:name => '追加', :sort_key => 77, :user_id => :hanako.to_id}, account_type: 'income'}
        end
        it_behaves_like 'current_userのincomeが登録される'
      end
      context "重複した名前" do
        before do
          post :create, params: {:account => {:name => '給料', :sort_key => 77}, account_type: 'income'}
        end
        it "エラーメッセージ" do
          expect(response).to be_successful
          expect(assigns(:account).errors).not_to be_empty
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
        put :update_all, params: {:account => @current_values, account_type: 'income'}
        expect(response).to redirect_to(settings_incomes_path)
        income = @current_user.incomes.find_by(name: 'きゅうりょう')
        expect(income).not_to be_nil
        expect(flash[:errors]).to be_nil
      end
      it "空の口座名をいれるとエラーメッセージ" do
        @current_values[:taro_salary.to_id.to_s][:name] = ""
        put :update_all, params: {:account => @current_values, account_type: 'income'}
        expect(response).to be_successful
        expect(@current_user.incomes.find_by(name: '給料')).not_to be_nil
        expect(assigns(:accounts).any?{|a| !a.errors.empty?}).to be_truthy
      end
      it "他人の口座の情報を混ぜると例外" do
        @current_values[:hanako_salary.to_id.to_s] = {:name => '花子の給料改'}
        expect {put :update_all, params: {:account => @current_values, account_type: 'income'}}.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    describe "destroy" do
      it "成功する" do
        delete :destroy, params: {:id => :taro_salary.to_id, account_type: 'income'}
        expect(response).to redirect_to(settings_incomes_path)
        expect(flash[:errors]).to be_nil
        expect(Account::Base.find_by(id: :taro_salary.to_id)).to be_nil
      end
      it "他人の口座を指定できない" do
        expect {delete :destroy, params: {:id => :hanako_salary.to_id, account_type: 'income'}}.to raise_error(ActiveRecord::RecordNotFound)
      end
      it "使っている口座は削除できない" do
        @current_user.general_deals.create!(:debtor_entries_attributes => [{:amount => 100, :account_id => :taro_cache.to_id}],
          :creditor_entries_attributes => [{:amount => -100, :account_id => :taro_salary.to_id}],
          :date => Time.zone.today
          )
        delete :destroy, params: {:id => :taro_salary.to_id, account_type: 'income'}
        expect(response).to redirect_to(settings_incomes_path)
        expect(flash[:errors]).not_to be_nil
        expect(@current_user.incomes.find_by(id: :taro_salary.to_id)).not_to be_nil
      end
    end
  end
end
