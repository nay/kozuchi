require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe User do
  fixtures :users, :accounts, :account_links, :account_link_requests, :friend_requests, :friend_permissions
  set_fixture_class  :accounts => Account::Base, :friend_requests => Friend::Request, :friend_permissions => Friend::Permission

  describe "destroy" do
    before do
      @user = users(:taro)
    end
    describe "Dealがないとき" do
      it "成功する" do
        raise "前提エラー：Dealがある" unless Deal::General.find_all_by_user_id(@user.id).empty?
        @user.destroy
        User.find_by_id(@user.id).should be_nil
      end
    end
    describe "Dealがあるとき" do
      before do
        new_deal(12, 1, accounts(:taro_cache), accounts(:taro_bank), 2000, 2009).save!
      end
      it "成功する" do
        @user.destroy
        User.find_by_id(@user.id).should be_nil
        # TODO AccountLinkRequest
        [Deal::Base, Entry::Base, AccountLink, AccountLinkRequest, Account::Base, Friend::Permission, Friend::Request, Settlement, Preferences].each do |klass|
          klass.find_by_user_id(@user.id).should be_nil
        end
#        AccountLinkRequest.find_by_sender_id(@user.id).should be_nil
#        AccountLinkRequest.find(:first, :include => :account, :conditions => "accounts.user_id = #{@user.id}").should be_nil
      end
    end
    describe "精算があるとき" do
      before do
        d = new_deal(12, 1, accounts(:taro_cache), accounts(:taro_hanako), 2000, 2009)
        d.save!
        s = Settlement.new
        s.user_id = d.user_id
        s.account_id = accounts(:taro_hanako).id
        s.result_partner_account_id = accounts(:taro_cache).id # TODO: わからなかった。Specほしい
        s.result_date = Date.new(2009, 4, 1) # TODO: 同上
        s.name = "テスト"
        s.target_entries << d.entries.detect{|e| e.account_id == accounts(:taro_hanako).id}
        s.save!
      end
      it "成功する" do
        @user.destroy
        User.find_by_id(@user.id).should be_nil
        Settlement.find_by_user_id(@user.id).should be_nil
      end
    end


  end

  def new_deal(month, day, from, to, amount, year = 2008)
    d = Deal::General.new(:summary => "#{month}/#{day}のデータ",
#      :amount => amount,
      :debtor_entries_attributes => [{:account_id => to.id, :amount => amount}],
      :creditor_entries_attributes => [{:account_id => from.id, :amount => amount.to_i * -1}],
#      :minus_account_id => from.id,
#      :plus_account_id => to.id,
      :date => Date.new(year, month, day))
    d.user_id = to.user_id
    d
  end

end