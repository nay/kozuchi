require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../controller_spec_helper')

describe Settings::AssetsController do
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
    share_examples_for 'current_userのassetが登録される' do
      it "current_userのassetが登録される" do
        response.should redirect_to(settings_assets_path)
        asset = @current_user.assets.find_by_name('追加')
        asset.should_not be_nil
        asset.asset_kind.should == 'cache'
        asset.sort_key.should == 77
        flash[:errors].should be_nil
      end
    end
    context "正しいパラメータ" do
      before do
        post :create, :account => {:name => '追加', :sort_key => 77, :asset_kind => 'cache'}
      end
      it_should_behave_like 'current_userのassetが登録される'
    end
    context "別のuser_idを指定" do
      before do
        post :create, :account => {:name => '追加', :sort_key => 77, :asset_kind => 'cache', :user_id => Fixtures.identify(:hanako)}
      end
      it_should_behave_like 'current_userのassetが登録される'
    end
    context "重複した名前" do
      before do
        post :create, :account => {:name => '現金', :sort_key => 77, :asset_kind => 'cache'}
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
      @current_user.assets.each{|a| @current_values[a.id.to_s] = {:name => a.name, :asset_kind => a.asset_kind, :sort_key => a.sort_key}}
    end
    it "成功する" do
      @current_values[:taro_cache.to_id.to_s][:name] = "げんきん"
      @current_values[:taro_cache.to_id.to_s][:asset_kind] = 'credit'
      put :update_all, :account => @current_values
      response.should redirect_to(settings_assets_path)
      asset = @current_user.assets.find_by_name('げんきん')
      asset.should_not be_nil
      asset.asset_kind.should == 'credit'
      flash[:errors].should be_nil
    end
    it "空の口座名をいれるとエラーメッセージ" do
      @current_values[:taro_cache.to_id.to_s][:name] = ""
      put :update_all, :account => @current_values
      response.should be_success
      @current_user.assets.find_by_name('現金').should_not be_nil
      assigns(:accounts).any?{|a| !a.errors.empty?}.should be_true
    end
    it "他人の口座の情報を混ぜると例外" do
      @current_values[:hanako_cache.to_id.to_s] = {:name => '花子の現金改'}
      lambda{put :update_all, :account => @current_values}.should raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "destroy" do
    it "成功する" do
      delete :destroy, :id => Fixtures.identify(:taro_cache)
      response.should redirect_to(settings_assets_path)
      Account::Base.find_by_id(Fixtures.identify(:taro_cache)).should be_nil
      flash[:errors].should be_nil
    end
    it "他人の口座を指定できない" do
      lambda{delete :destroy, :id => Fixtures.identify(:hanako_cache)}.should raise_error(ActiveRecord::RecordNotFound)
    end
    it "使っている口座は削除できない" do
      @current_user.general_deals.create!(:debtor_entries_attributes => [{:amount => 100, :account_id => :taro_food.to_id}],
        :creditor_entries_attributes => [{:amount => -100, :account_id => :taro_cache.to_id}],
        :date => Date.today
        )
      delete :destroy, :id => :taro_cache.to_id
      response.should redirect_to(settings_assets_path)
      flash[:errors].should_not be_nil
      @current_user.assets.find_by_id(:taro_cache.to_id).should_not be_nil
    end
  end

end