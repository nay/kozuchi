require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../controller_spec_helper')

describe SettlementsController, type: :controller do
  fixtures :users, :friend_requests, :friend_permissions, :accounts, :account_links, :account_link_requests

  before do
    login_as :taro
  end

  response_should_be_redirected_without_login {get :summary, params: {year: Time.zone.today.year, month: Time.zone.today.month}}

  describe "new" do
    it "成功する" do
      get :new, params: {account_id: :taro_card.to_id, year: '2010', month: '6'}
      expect(response).to be_successful
    end
  end

  describe "update_source" do
    it "十分なパラメータがないと例外" do
      expect{ put :update_source, params: {account_id: :taro_card.to_id, year: '2010', month: '6'} }.to raise_error(InvalidParameterError)
    end
    it "成功する" do
      put :update_source, params: {
          source: {
              start_date: {year: '2010', month: '5', day: '1'},
              end_date:   {year: '2010', month: '5', day: '1'},
              target_account_id: :taro_cache.to_id,
              paid_on: {year: '2010', month: '6', day: '1'}
          },
          account_id: :taro_card.to_id,
          year: '2010',
          month: '6'
      }
      expect(response).to be_successful
    end
  end

  describe "summary" do
    before do
      get 'summary', params: {year: Time.zone.today.year, month: Time.zone.today.month}
    end
    it "成功する" do
      expect(response).to be_successful
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
      post :create, params: {
          :source => {
            start_date: {year: '2010', month: '5', day: '1'},
            end_date:   {year: '2010', month: '6', day: '1'},
            name: 'テスト精算2010-5',
            description: '',
            target_account_id: :taro_bank.to_id.to_s,
            deal_ids: {@deal.id.to_s => "1"},
            paid_on: {year: '2010', month: '6', day: '30'},
            },
          account_id: :taro_hanako.to_id,
          year: '2010',
          month: '6'
      }
      expect(response).to redirect_to(settlements_path(year: '2010', month: '6'))
      expect(@current_user.settlements.find_by(name: 'テスト精算2010-5')).not_to be_nil
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
        :deal_ids => [@deal.id],
        :result_date => Date.new(2010, 6, 30)
      )
      @settlement.save!
    end
    it "成功する" do
      post :submit, params: {:id => @settlement.id}
      expect(response).to redirect_to(settlement_path(:id => @settlement.id))
      # TODO: 内部の変更確認
    end
    
  end

  describe "show" do
    before do
      @settlement = create_taro_settlement
    end
    it "成功する" do
      get :show, params: {:id => @settlement.id}
      expect(response).to be_successful
    end
  end

  describe "print_form" do
    before do
      @settlement = create_taro_settlement
    end
    it "成功する" do
      get :print_form, params: {:id => @settlement.id}
      expect(response).to be_successful
    end
  end

  describe "destroy" do
    before do
      @settlement = create_taro_settlement
      delete :destroy, params: {:id => @settlement.id}
    end
    it "リダイレクトされる" do
      expect(response).to redirect_to(settlements_path(year: @settlement.year, month: @settlement.month))
    end
    it "実際に削除されている" do
      expect(Settlement.find_by(id: @settlement.id)).to be_nil
    end
  end

  # 汎用性なし
  def create_taro_settlement
    d = new_deal(3, 1, accounts(:taro_card), accounts(:taro_food), 6000)
    d.save!
    s = users(:taro).settlements.build(:deal_ids => [d.id], :account_id => accounts(:taro_card).id, :name => "テスト精算", :result_date => Date.new(2008, 3, 5), :result_partner_account_id => accounts(:taro_bank).id)
    s.save!
    s
  end

  # TODO: DRY
  def new_deal(month, day, from, to, amount, year = 2008)
    d = Deal::General.new(:summary => "#{month}/#{day}の買い物",
      :debtor_entries_attributes => [{:account_id => to.id, :amount => amount}],
      :creditor_entries_attributes => [{:account_id => from.id, :amount => amount.to_i * -1}],
      :date => Date.new(year, month, day))
    d.user_id = to.user_id
    d
  end

end
