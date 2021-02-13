require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "Account with Account::Linking" do
  fixtures :users, :friend_permissions, :friend_requests, :accounts

  before do
    @taro = users(:taro)
    @hanako = users(:hanako)
    @home = users(:home)
  end
  
  describe "set_link" do
    it "太郎の花子から花子の太郎へ双方向にリンクできる" do
      @taro_hanako = accounts(:taro_hanako)
      @hanako_taro = accounts(:hanako_taro)

      @taro_hanako.set_link(@hanako, @hanako_taro, true)
      expect(@taro_hanako.link).not_to be_nil
      expect(@taro_hanako.link.target_ex_account_id).to eq :hanako_taro.to_id
      expect(@taro_hanako.link.target_user_id).to eq :hanako.to_id

      expect(@hanako_taro.link).not_to be_nil
      expect(@hanako_taro.link.target_ex_account_id).to eq :taro_hanako.to_id
      expect(@hanako_taro.link.target_user_id).to eq :taro.to_id
    end
    describe "太郎のtestと家計のtestが双方向連携しているとき" do
      before do
        @taro_test = @taro.expenses.build(:name => 'test')
        @taro_test.save!
        @home_test = @home.incomes.build(:name => 'test')
        @home_test.save!
        @hanako_test = @hanako.expenses.build(:name => 'test')
        @hanako_test.save!
        @taro_test.set_link(@home, @home_test, true)
      end
      it "花子から双方向連携しようとしても、家計側からのリンクを変えられない" do
        expect{ @hanako_test.set_link(@home, @home_test, true) }.to raise_error(User::AccountLinking::AccountHasDifferentLinkError)
        @home_test.reload
        # リンクは変わっていない
        expect(@home_test.link.target_account).to eq @taro_test
        # link request は増えている
        expect(@home_test.link_requests.find_by(sender_id: @hanako.id, sender_ex_account_id: @hanako_test.id)).not_to be_nil
        # 花子からのリンクはできている
        expect(@hanako_test.link.target_account).to eq @home_test
      end
      it "太郎から再度双方向連携を指定してもうまくいく" do
        expect{ @taro_test.set_link(@home, @home_test, true) }.not_to raise_error
        @taro_test.reload
        @home_test.reload
        expect(@taro_test.link.target_account).to eq @home_test
        expect(@home_test.link.target_account).to eq @taro_test
      end
      it "太郎から別の勘定に双方向連携をはったらはりなおせて、太郎から家計への連携は削除されるが、家計から太郎へのリンクは削除されない" do
        @home_test2 = @home.incomes.build(:name => 'test2')
        @home_test2.save!
        expect{ @taro_test.set_link(@home, @home_test2, true) }.not_to raise_error
        @taro_test.reload
        @home_test.reload
        @home_test2.reload
        expect(@taro_test.link.target_account).to eq @home_test2
        expect(@home_test2.link.target_account).to eq @taro_test
        expect(@home_test.link.target_account).to eq @taro_test
        expect(@taro_test.link_requests.find_by(sender_id: @home.id, sender_ex_account_id: @home_test.id)).not_to be_nil
        expect(@home_test.link_requests.find_by(sender_id: @taro.id, sender_ex_account_id: @taro_test.id)).to be_nil
      end
    end
  end
end
