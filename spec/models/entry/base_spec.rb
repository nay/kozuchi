require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Entry::Base do
  fixtures :accounts, :users, :account_links, :friend_permissions, :friend_requests

  before do
    @cache = accounts(:account_enrty_test_cache)
    @food = accounts(:account_entry_test_food)

    @user_hanako = users(:account_entry_test_user_hanako)
    @user_taro = users(:account_entry_test_user_taro)
    @hanako_in_taro = accounts(:account_entry_test_hanako_in_taro)
    @cache_in_taro = accounts(:account_entry_test_cache_in_taro)
    @taro_in_hanako = accounts(:account_entry_test_taro_in_hanako)
    @cache_in_hanako = accounts(:account_entry_test_cache_in_hanako)

    raise "前提エラー：@user_hanakoと@user_taroが友達ではありません" unless @user_hanako.friend?(@user_taro)
    raise "前提エラー：@hanako_in_taroに記入したものが@taro_in_hanakoに記入される設定になっていません" unless @hanako_in_taro.destination_account == @taro_in_hanako
  end

  describe "amount=" do
    it "コンマ入りの数字が正規化されて代入される" do
      expect(new_account_entry(:amount => "10,000").amount.to_i).to eq 10000
    end
  end

  describe "validate" do
    it "amountが指定されていないと検証エラー" do
      expect(new_account_entry(:amount => nil).valid?).to be_falsey
    end
    it "account_idが指定されていないと検証エラー" do
      expect(new_account_entry(:account_id => nil).valid?).to be_falsey
    end
    it "account_idが対応するユーザーのものでないと検証エラー" do
      expect(new_account_entry({:account_id => Fixtures.identify(:taro_cache), :amount => 300}, {:user_id => Fixtures.identify(:hanako)})).not_to be_valid
    end
  end

  describe "create" do
    it "account_id, amount, date, daily_seq, user_id があれば、deal_id の値によらず成功する" do
      e = Entry::General.new(:amount => 400, :account_id => @cache.id)
      e.date = Time.zone.today
      e.daily_seq = 1
      e.user_id = Fixtures.identify(:account_entry_test_user)
      expect(e.save).to be_truthy
    end
    it "user_idがないと例外" do
      expect{ new_account_entry({}, :user_id => nil).save }.to raise_error(RuntimeError)
    end
    it "dateがないと例外" do
      expect{ new_account_entry({}, :date => nil).save }.to raise_error(RuntimeError)
    end
    it "daily_seqがないと例外" do
      expect{ new_account_entry({}, :daily_seq => nil).save }.to raise_error(RuntimeError)
    end
  end


  describe "destroy" do
    it "精算が紐付いていなければ消せる" do
      e = new_account_entry
      e.save!
      expect{ e.destroy }.not_to raise_error
    end
  end

  describe "settlement_attached?" do
    before do
      @entry = new_account_entry
    end
    it "settlement_id も result_settlement_idもないとき falseとなる" do
      @entry.save!
      expect(@entry.settlement_attached?).to be_falsey
    end
    it "settlement_id があれば true になる" do
      @entry.settlement_id = 130 # 適当
      @entry.save!
      expect(@entry.settlement_attached?).to be_truthy
    end
    it "result_settlement_id があれば true になる" do
      @entry.result_settlement_id = 130 # 適当
      @entry.save!
      expect(@entry.settlement_attached?).to be_truthy
    end
  end

  describe "mate_account_name" do
    it "紐付いたdealがなければAssociatedObjectMissingErrorが発生する" do
      @entry = new_account_entry
      @entry.save!
      expect{ @entry.mate_account_name }.to raise_error(AssociatedObjectMissingError)
    end

    it "相手勘定が１つなら、相手勘定の名前が返される" do
      deal = new_deal(3, 3, @cache, @food, 180)
      deal.save!
#        deal = Deal::General.new(:summary => "買い物", :date => Time.zone.today)
#        deal.entries.build(:amount => 180, :account_id => @food.id)
#        deal.entries.build(:amount => -180, :account_id => @cache.id)
#        deal.save!
      cache_entry = deal.entries.detect{|e| e.account_id == @cache.id}
      expect(cache_entry.mate_account_name).to eq @food.name
    end
  end

  describe "unlink" do
    before do
#      @deal = Deal::General.new(:summary => "test", :date => Time.zone.today)
#      @deal.user_id = users(:account_entry_test_user_taro)
#      @deal.entries.build(
#        :account_id => @cache_in_taro.id,
#        :amount => -200
#        )
#      @deal.entries.build(
#        :account_id => @hanako_in_taro.id,
#        :amount => 200
#        )
#      @entry.save!

      @entry = Entry::General.new(:account_id => @hanako_in_taro.id, :amount => -200)
      @entry.daily_seq = 1
      @entry.date = Time.zone.today
      @entry.linked_ex_entry_id = 18 # 適当
      @entry.user_id = Fixtures.identify(:account_entry_test_user_taro)
    end
    it "linked_ex_entry_idを指定した新規登録なら連携記入がされないこと" do
      @entry.save!
      expect(Entry::Base.find_by(linked_ex_entry_id: @entry.id)).to be_nil
    end
    
  end


  # ----- Utilities -----
  def new_account_entry(attributes = {}, manual_attributes = {})
      e = Entry::General.new({:amount => 2980, :account_id => @cache.id}.merge(attributes))
      user_id = e.account.try(:user_id)
      manual_attributes = {:date => Time.zone.today, :daily_seq => 1, :user_id => user_id}.merge(manual_attributes)
      manual_attributes.keys.each do |key|
        e.send("#{key}=", manual_attributes[key])
      end
      e
  end
  
  # TODO: dealの作り方をなおすまでとりあえず
  def new_deal(month, day, from, to, amount, year = 2008)
    d = Deal::General.new(:summary => "#{month}/#{day}の買い物",
      :debtor_entries_attributes => [{:account_id => to.id, :amount => amount}],
      :creditor_entries_attributes => [{:account_id => from.id, :amount => amount.to_i*-1}],
      :date => Date.new(year, month, day))
    d.user_id = to.user_id
    d
  end

end
