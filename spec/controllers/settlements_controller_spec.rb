require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../controller_spec_helper')

describe SettlementsController do
  fixtures :users, :friend_requests, :friend_permissions, :accounts, :account_links, :account_link_requests
  set_fixture_class  :accounts => Account::Base

  before do
    login_as :taro
  end

  response_should_be_redirected_without_login {get :index}

  describe "new" do
    it "成功する" do
      get :new
      response.should be_success
    end
  end

  describe "target_deals" do
    it "十分なパラメータがないと例外" do
      lambda{get :target_deals}.should raise_error(InvalidParameterError)
    end
    it "成功する" do
      get :target_deals,
        :start_date => {:year => '2010', :month => '5', :day => '1'},
        :end_date => {:year => '2010', :month => '5', :day => '1'},
        :settlement => {:account_id => :taro_cache.to_id}
      response.should be_success
    end
  end

  describe "index" do
    it "精算データがない時、成功する" do
      raise "there are settlements!" unless @current_user.settlements.empty?
      get 'index'
      response.should be_success
    end
    it "精算データがある時、成功する" do
      create_taro_settlement
      get 'index'
      response.should be_success
    end
  end

  describe "create" do
    before do
      @deal = @current_user.general_deals.build(:summary => '貸した',
      :date => {:year => '2010', :month => '5', :day => '5'},
      :debtor_entries_attributes => [{:account_id => :taro_hanako.to_id, :amount => 3000}],
      :creditor_entries_attributes => [{:account_id => :taro_cache.to_id, :amount => -3000}]
      )
      @deal.save!
    end
    it "成功する" do
      post :create, :settlement => {
        :account_id => :taro_hanako.to_id.to_s,
        :name => 'テスト精算2010-5',
        :description => '',
        :result_partner_account_id => :taro_bank.to_id.to_s,
        :deal_ids => {@deal.id.to_s => '1'}
        }, :result_date => {:year => '2010', :month => '6', :day => '30'}

      response.should redirect_to(settlements_path)
      @current_user.settlements.find_by_name('テスト精算2010-5').should_not be_nil
    end
  end

  describe "submit " do
    before do
      @deal = @current_user.general_deals.build(:summary => '貸した',
      :date => {:year => '2010', :month => '5', :day => '5'},
      :debtor_entries_attributes => [{:account_id => :taro_hanako.to_id, :amount => 3000}],
      :creditor_entries_attributes => [{:account_id => :taro_cache.to_id, :amount => -3000}]
      )
      @deal.save!
      @settlement = @current_user.settlements.build(
        :account_id => :taro_hanako.to_id.to_s,
        :name => 'テスト精算2010-5',
        :description => '',
        :result_partner_account_id => :taro_bank.to_id.to_s,
        :deal_ids => {@deal.id.to_s => '1'},
        :result_date => Date.new(2010, 6, 30)
      )
      @settlement.save!
    end
    it "成功する" do
      post :submit, :id => @settlement.id
      response.should redirect_to(settlement_path(:id => @settlement.id))
      # TODO: 内部の変更確認
    end
    
  end

  describe "show" do
    before do
      @settlement = create_taro_settlement
    end
    it "成功する" do
      get :show, :id => @settlement.id
      response.should be_success
    end
  end

  describe "print_form" do
    before do
      @settlement = create_taro_settlement
    end
    it "formatなしで成功する" do
      get :print_form, :id => @settlement.id
      response.should be_success
    end
    it "formatありで成功する" do
      get :print_form, :id => @settlement.id, :format => "csv"
      response.should be_success
    end
  end

  describe "destroy" do
    before do
      @settlement = create_taro_settlement
      delete :destroy, :id => @settlement.id
    end
    it "リダイレクトされる" do
      response.should redirect_to(settlements_path)
    end
    it "実際に削除されている" do
      Settlement.find_by_id(@settlement.id).should be_nil
    end
  end

  # 汎用性なし
  def create_taro_settlement
    d = new_deal(3, 1, accounts(:taro_card), accounts(:taro_food), 6000)
    d.save!
    s = users(:taro).settlements.build(:deal_ids => {d.id.to_s => "1"}, :account_id => accounts(:taro_card).id, :name => "テスト精算", :result_date => Date.new(2008, 3, 5), :result_partner_account_id => accounts(:taro_bank).id)
    s.save!
    s
  end

  # TODO: DRY
  def new_deal(month, day, from, to, amount, year = 2008)
    d = Deal::General.new(:summary => "#{month}/#{day}の買い物",
      :debtor_entries_attributes => [{:account_id => to.id, :amount => amount}],
      :creditor_entries_attributes => [{:account_id => from.id, :amount => amount.to_i * -1}],
#      :amount => amount, :minus_account_id => from.id,
#      :plus_account_id => to.id,
      :date => Date.new(year, month, day))
    d.user_id = to.user_id
    d
  end

end
