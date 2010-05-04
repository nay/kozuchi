require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../controller_spec_helper')

describe Settings::IncomesController do
  fixtures :users, :preferences, :accounts
  set_fixture_class :accounts => 'Account::Base', :preferences => 'Preferences'


  before do
    login_as :taro
  end

  response_should_be_redirected_without_login { get :index }

  describe "index" do
    it "成功する" do
      get :index
      response.should be_success
    end
  end

  describe "create" do
    share_examples_for 'current_userのincomeが登録される' do
      it "current_userのincomeが登録される" do
        response.should redirect_to(settings_incomes_path)
        income = @current_user.incomes.find_by_name('追加')
        income.should_not be_nil
        income.sort_key.should == 77
        flash[:errors].should be_nil
      end
    end
    context "正しいパラメータ" do
      before do
        post :create, :account => {:name => '追加', :sort_key => 77}
      end
      it_should_behave_like 'current_userのincomeが登録される'
    end
    context "別のuser_idを指定" do
      before do
        post :create, :account => {:name => '追加', :sort_key => 77, :user_id => :hanako.to_id}
      end
      it_should_behave_like 'current_userのincomeが登録される'
    end
    context "重複した名前" do
      before do
        post :create, :account => {:name => '給料', :sort_key => 77}
      end
      it "エラーメッセージ" do
        response.should be_success
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
      put :update_all, :account => @current_values
      response.should redirect_to(settings_incomes_path)
      income = @current_user.incomes.find_by_name('きゅうりょう')
      income.should_not be_nil
      flash[:errors].should be_nil
    end
    it "空の口座名をいれるとエラーメッセージ" do
      @current_values[:taro_salary.to_id.to_s][:name] = ""
      put :update_all, :account => @current_values
      response.should be_success
      @current_user.incomes.find_by_name('給料').should_not be_nil
      assigns(:accounts).any?{|a| !a.errors.empty?}.should be_true
    end
    it "他人の口座の情報を混ぜると例外" do
      @current_values[:hanako_salary.to_id.to_s] = {:name => '花子の給料改'}
      lambda{put :update_all, :account => @current_values}.should raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "destroy" do
    it "成功する" do
      delete :destroy, :id => :taro_salary.to_id
      response.should redirect_to(settings_incomes_path)
      Account::Base.find_by_id(:taro_salary.to_id).should be_nil
      flash[:errors].should be_nil
    end
    it "他人の口座を指定できない" do
      lambda{delete :destroy, :id => :hanako_salary.to_id}.should raise_error(ActiveRecord::RecordNotFound)
    end
    it "使っている口座は削除できない" do
      @current_user.general_deals.create!(:debtor_entries_attributes => [{:amount => 100, :account_id => :taro_cache.to_id}],
        :creditor_entries_attributes => [{:amount => -100, :account_id => :taro_salary.to_id}],
        :date => Date.today
        )
      delete :destroy, :id => :taro_salary.to_id
      response.should redirect_to(settings_incomes_path)
      flash[:errors].should_not be_nil
      @current_user.incomes.find_by_id(:taro_salary.to_id).should_not be_nil
    end
  end

end