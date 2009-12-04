require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe SettlementsController do
  fixtures :users, :accounts
  set_fixture_class  :accounts => Account::Base

  before do
    login_as :taro
    @current_user = users(:taro)
  end

  describe "index" do
    it "ログインしていないとリダイレクトされる" do
      login_as nil
      get 'index'
      response.should redirect_to root_path
    end
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

  describe "new" do
    it "成功する" do
      get :new
      response.should be_success
    end
  end

  # TDOO: createはもう少しパラメータ整理しないとかけない

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
    d = Deal::General.new(:summary => "#{month}/#{day}の買い物", :amount => amount, :minus_account_id => from.id, :plus_account_id => to.id, :date => Date.new(year, month, day))
    d.user_id = to.user_id
    d
  end

end
