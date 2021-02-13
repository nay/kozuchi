require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe Deal::General do
  fixtures :accounts, :account_links, :account_link_requests, :friend_requests, :friend_permissions, :users

  before do
    @cache = accounts(:deal_test_cache)
    @bank = accounts(:deal_test_bank)
  end

  describe "#confirm!" do
    context "初回残高記入よりも前に未確定記入があるとき" do
      # 800円 現金→食費
      let!(:deal) { create(:general_deal, :date => Date.new(2012, 12, 1), :confirmed => false) }
      let!(:initial_balance) { create(:balance_deal, :date => Date.new(2012, 12, 5), :balance => 1000)}

      it "現金の初回残高記入のamountは1000である" do
        expect(initial_balance.amount).to eq 1000
      end

      context "未確定記入(現金からの支出800円)を確定したとき" do
        before do
          deal.confirm!
          initial_balance.reload
        end
        it "初回残高記入のamountは1800である" do
          expect(initial_balance.amount).to eq 1800
        end
      end
    end
  end

  describe "new" do
    it "複数行のDealオブジェクトの作成に成功すること" do

      # 食費 1300   現金 1000
      #            銀行  300
      deal = Deal::General.new(:summary => "複数行", :date => Date.new,
        :debtor_entries_attributes => [{
            :account_id => Fixtures.identify(:taro_food),
            :amount => 1300
          }],
        :creditor_entries_attributes => [{
            :account_id => Fixtures.identify(:taro_cache),
            :amount => -1000
          },
          {
            :account_id => Fixtures.identify(:taro_bank),
            :amount => -300
          }
        ]
      )
      expect(deal.debtor_entries.size).to eq 1
      expect(deal.creditor_entries.size).to eq 2
    end
  end

  describe "valid?" do
    it "数字の合った複合Dealが検証をとおること" do
      deal = new_complex_deal(3, 1, {:taro_food => 1300},{:taro_cache => -1000, :taro_bank => -300})
      expect(deal.valid?).to be_truthy
    end
    it "数字の合わない複合Dealが検証を通らないこと" do
      deal = new_complex_deal(3, 1, {:taro_food => 1300},{:taro_cache => -1000, :taro_bank => -200})
      expect(deal.valid?).to be_falsey
    end
    it "amountが0のEntryを含む複合Dealが検証を通らないこと" do
      deal = new_complex_deal(3, 1, {:taro_food => 1300},{:taro_cache => -1300, :taro_bank => 0})
      expect(deal.valid?).to be_falsey
    end
    it "複合Dealの各Entryの口座に重複があっても構わない" do
      deal = new_complex_deal(3, 1, {:taro_food => 1400}, {:taro_cache => -1300, :taro_food => -100})
      expect(deal.valid?).to be_truthy
    end

    it "同じ口座間での移動が検証を通る" do
      deal = new_simple_deal(3, 1, :taro_food, :taro_food, 300)
      expect(deal.valid?).to be_truthy
    end
    it "金額が0ではいけないこと" do
      deal = new_simple_deal(3, 1, :taro_food, :taro_cache, 0)
      deal.valid?
      expect(deal.valid?).to be_falsey
    end
  end

  describe "create" do

    it "数字の合った複合Dealが作成できること" do
      deal = new_complex_deal(3, 1, {:taro_food => 1300},{:taro_cache => -1000, :taro_bank => -300})
      expect(deal.save).to be_truthy
    end
    it "カンマ入り数字による複合Dealが作成できること" do
      deal = new_complex_deal(3, 1, {:taro_food => '1,300'},{:taro_cache => '-1,000', :taro_bank => '-300'})
      expect(deal.save).to be_truthy
      expect(deal.debtor_entries.any?{|e| e.amount.to_i == 1300}).to be_truthy
    end
    it "複合Dealの各Entryの口座に重複があっても作成できること" do
      deal = new_complex_deal(3, 1, {:taro_food => 1400}, {:taro_cache => -1300, :taro_food => -100})
      expect(deal.save).to be_truthy

      d = deal.debtor_entries.first
      expect(d.account_id).to eq Fixtures.identify(:taro_food)
      expect(d.amount).to eq 1400

      c = deal.creditor_entries.first
      expect(c.account_id).to eq Fixtures.identify(:taro_cache)
      expect(c.amount).to eq -1300

      c = deal.creditor_entries.last
      expect(c.account_id).to eq Fixtures.identify(:taro_food)
      expect(c.amount).to eq -100
    end
    it "片側に空白欄のある複合Dealが作成でき、空白欄の分が維持される" do
      deal = build(:complex_deal,
        :debtor_entries_attributes =>  [{:account_id => Fixtures.identify(:taro_food), :amount => 800, :line_number => 0}, {:account_id => Fixtures.identify(:taro_other), :amount => 200, :line_number => 1}],
        :creditor_entries_attributes => [:account_id => Fixtures.identify(:taro_cache), :amount => -1000, :line_number => 1] # 0でない
      )
      expect(deal.save).to be_truthy
      expect(deal.creditor_entries.first.line_number).to eq 1
    end
    it "両側に空白欄のある複合Dealが作成でき、空白分が詰められる" do
      deal = build(:complex_deal,
        :debtor_entries_attributes =>  [{:account_id => Fixtures.identify(:taro_food), :amount => 800, :line_number => 0}, {:account_id => Fixtures.identify(:taro_other), :amount => 200, :line_number => 2}],
        :creditor_entries_attributes => [:account_id => Fixtures.identify(:taro_cache), :amount => -1000, :line_number => 2] # 0, 1でない
      )
      expect(deal.save).to be_truthy
      expect(deal.debtor_entries.map(&:line_number)).to eq [0, 1]
      expect(deal.creditor_entries.first.line_number).to eq 1
    end

    it "同じ口座間での移動記入が作成できること" do
      deal = new_simple_deal(3, 1, :taro_food, :taro_food, 300)
      expect(deal.save).to be_truthy
      d = deal.debtor_entries.first
      expect(d.account_id).to eq Fixtures.identify(:taro_food)
      expect(d.amount).to eq 300

      c = deal.creditor_entries.first
      expect(c.account_id).to eq Fixtures.identify(:taro_food)
      expect(c.amount).to eq -300
    end

    describe "連携なし" do
      before do
        @deal = new_simple_deal(6, 1, @cache, @bank, 3500)
      end

      it "成功する" do
        expect(@deal.save).to be_truthy
      end

      it "user_id, date, daily_seqがentriesに引き継がれる" do
        @deal.save!
        expect(@deal.entries.detect{|e| e.user_id != @deal.user_id || e.date != @deal.date || e.daily_seq != @deal.daily_seq}).to be_nil
      end

      it "account_entryを手動で足してもcreateできる" do
        user = users(:deal_test_user)
        deal = Deal::General.new(:summary => "test", :date => Time.zone.today)
        deal.user_id = user.id
        deal.creditor_entries.build(
          :account_id => @cache.id,
          :amount => -10000)
        deal.debtor_entries.build(
          :account_id => @bank.id,
          :amount => 10000)
        expect(deal.save).to be_truthy
        expect(deal.creditor_entries.detect{|e| e.new_record?}).to be_nil
        expect(deal.debtor_entries.detect{|e| e.new_record?}).to be_nil
      end
    end

  end

  describe "update" do
    let!(:deal) do
      Timecop.travel(10.minutes.ago) do
        d = new_simple_deal(6, 1, @cache, @bank, 3500)
        d.save!
        d
      end
    end
    let!(:old_time_stamp) { deal.created_at }
    before do
      @deal = deal # TODO: 互換性のためいったん残す
      @deal.reload
    end
    # 複数記入への変更
    it "貸し方の項目を足して複数記入に変更できる" do
      @deal.attributes = {
        :creditor_entries_attributes => {
          '0' => {:account_id => @cache.id, :amount => -3200, :id => @deal.creditor_entries.first.id, :line_number => 0},
          '1' => {:account_id => :deal_test_food.to_id, :amount => -300, :line_number => 1}
        },
        :debtor_entries_attributes => {
          '0' => {:account_id => @bank.id, :amount => 3500, :id => @deal.debtor_entries.first.id, :line_number => 0}
        }
      }
      expect(@deal.creditor_entries.size).to eq 3 # 一時的に３つになる
      expect(@deal.creditor_entries.first.marked_for_destruction?).to be_truthy
      expect(@deal.creditor_entries[1].amount).to eq -3200
      expect(@deal.creditor_entries[2].amount).to eq -300
      expect(@deal.valid?).to be_truthy
      expect(@deal.save).to be_truthy
      @deal.reload
      expect(@deal.creditor_entries.size).to eq 2
      expect(@deal.debtor_entries.size).to eq 1
      # 古いentryがnullifyでのこっていないこと
      expect(Entry::Base.find_by(deal_id: nil)).to be_nil
    end
    it "借り方の項目を足して複数記入に変更できる" do
      @deal.attributes = {
        :creditor_entries_attributes => {
          '0' => {:account_id => @cache.id, :amount => -3500, :id => @deal.creditor_entries.first.id, :line_number => 0}
        },
        :debtor_entries_attributes => {
          '0' => {:account_id => @bank.id, :amount => 3200, :id => @deal.debtor_entries.first.id, :line_number => 0},
          '1' => {:account_id => :deal_test_food.to_id, :amount => 300, :line_number => 1}
        }
      }
      expect(@deal.debtor_entries.size).to eq 3 # 一時的に３つになる
      expect(@deal.debtor_entries.first.marked_for_destruction?).to be_truthy
      expect(@deal.debtor_entries[1].amount).to eq 3200
      expect(@deal.debtor_entries[2].amount).to eq 300
      expect(@deal.valid?).to be_truthy
      expect(@deal.save).to be_truthy
      @deal.reload
      expect(@deal.creditor_entries.size).to eq 1
      expect(@deal.debtor_entries.size).to eq 2
      # 古いentryがnullifyでのこっていないこと
      expect(Entry::Base.find_by(deal_id: nil)).to be_nil
    end
    context "日付を変更したとき" do
      before do
        deal.reload # セーブ前の状態で deal 内の entry に deal が存在しているとentry保存時に日付が巻きもどるのでクリーンにしておく
        deal.date = deal.date - 7
        deal.save!
      end
      it "entriesのdateも変更される" do
        expect(deal.entries.detect{|e| e.user_id != deal.user_id || e.date != deal.date || e.daily_seq != deal.daily_seq}).to be_nil
      end
      it "dealのcreated_atは変化せず、updated_atは更新される" do
        expect(deal.created_at.to_s).to eq old_time_stamp.to_s
        expect(deal.updated_at.to_s).not_to eq old_time_stamp.to_s
      end
    end
    context "摘要を変更したとき" do
      before do
        deal.summary = "#{deal.summary}（仮）"
        deal.save!
      end
      it "dealのcreated_atは変化せず、updated_atは更新される" do
        expect(deal.created_at.to_s).to eq old_time_stamp.to_s
        expect(deal.updated_at.to_s).not_to eq old_time_stamp.to_s
      end
    end

    it "NestedAttributesを使って変更なしでsave!されたとき、entryが変化しない" do
      old_debtor_entry = @deal.debtor_entries.first
      old_creditor_entry = @deal.creditor_entries.first
      @deal.attributes = {
        :debtor_entries_attributes => {'0' => {:account_id => @bank.id, :amount => 3500, :id => old_debtor_entry.id}},
        :creditor_entries_attributes => {'0' => {:account_id => @cache.id, :amount => -3500, :id => old_creditor_entry.id}}
      }
      @deal.save!

      @deal.reload
      expect(@deal.debtor_entries.size).to eq 1
      new_debtor_entry = @deal.debtor_entries.first
      expect(new_debtor_entry.id).to eq old_debtor_entry.id
      expect(new_debtor_entry.amount).to eq old_debtor_entry.amount
      expect(new_debtor_entry.account_id).to eq old_debtor_entry.account_id
      expect(new_debtor_entry.user_id).to eq old_debtor_entry.user_id

      expect(@deal.creditor_entries.size).to eq 1
      new_creditor_entry = @deal.creditor_entries.first
      expect(new_creditor_entry.id).to eq old_creditor_entry.id
      expect(new_creditor_entry.amount).to eq old_creditor_entry.amount
      expect(new_creditor_entry.account_id).to eq old_creditor_entry.account_id
      expect(new_creditor_entry.user_id).to eq old_creditor_entry.user_id
    end
  
    context "with a complex deal" do
      let!(:deal) {
        create(:complex_deal,
          :debtor_entries_attributes =>  [{:account_id => Fixtures.identify(:taro_food), :amount => 800, :line_number => 0}, {:account_id => Fixtures.identify(:taro_other), :amount => 200, :line_number => 1}],
          :creditor_entries_attributes => [:account_id => Fixtures.identify(:taro_cache), :amount => -1000, :line_number => 1] # 0でない
        )
      }
      it "複数仕訳のDealの上側のEntryの金額を更新すると、idは変わるが位置は変わらない" do
        entry = deal.debtor_entries.first
        deal.debtor_entries_attributes = [{:account_id => Fixtures.identify(:taro_food), :amount => 900, :line_number => 0}, {:account_id => Fixtures.identify(:taro_other), :amount => 200, :line_number => 1}]
        deal.creditor_entries_attributes = [:account_id => Fixtures.identify(:taro_cache), :amount => -1100, :line_number => 1]
        expect{ deal.save! }.not_to raise_error
        deal.reload

        expect(deal.debtor_entries.first.id).not_to eq entry.id
        expect(deal.debtor_entries.first.account_id).to eq entry.account_id
        expect(deal.debtor_entries.first.line_number).to eq entry.line_number
      end
    end

    context "複数仕訳で口座と金額の組み合わせが同じ項目が複数あるとき" do
      let!(:deal) {
        create(:complex_deal,
          :debtor_entries_attributes =>  [{:account_id => Fixtures.identify(:taro_food), :amount => 500, :line_number => 0}, {:account_id => Fixtures.identify(:taro_food), :amount => 500, :line_number => 1}],
          :creditor_entries_attributes => [:account_id => Fixtures.identify(:taro_cache), :amount => -1000, :line_number => 0]
        )
      }
      it "NestedAttributesを使って変更なしでsave!されたとき、entryが変化しない" do
        old_debtor_entries = deal.debtor_entries.to_a
        old_creditor_entry = deal.creditor_entries.first
        deal.attributes = {
          :debtor_entries_attributes => {
            '0' => {:account_id => Fixtures.identify(:taro_food), :amount => 500, :line_number => 0, :id => old_debtor_entries[0].id},
            '1' => {:account_id => Fixtures.identify(:taro_food), :amount => 500, :line_number => 1, :id => old_debtor_entries[1].id}
          },
          :creditor_entries_attributes => {
            '0' => {:account_id => Fixtures.identify(:taro_cache), :amount => -1000, :line_number => 0, :id => old_creditor_entry.id}
          }
        }
        expect{ deal.save! }.not_to raise_error

        deal.reload
        expect(deal.debtor_entries.size).to eq 2
        new_debtor_entries = deal.debtor_entries.to_a
        expect(new_debtor_entries[0].id).to eq old_debtor_entries[0].id
        expect(new_debtor_entries[0].amount).to eq old_debtor_entries[0].amount
        expect(new_debtor_entries[0].account_id).to eq old_debtor_entries[0].account_id
        expect(new_debtor_entries[0].user_id).to eq old_debtor_entries[0].user_id
        expect(new_debtor_entries[0].line_number).to eq old_debtor_entries[0].line_number
        expect(new_debtor_entries[1].id).to eq old_debtor_entries[1].id
        expect(new_debtor_entries[1].amount).to eq old_debtor_entries[1].amount
        expect(new_debtor_entries[1].account_id).to eq old_debtor_entries[1].account_id
        expect(new_debtor_entries[1].user_id).to eq old_debtor_entries[1].user_id
        expect(new_debtor_entries[1].line_number).to eq old_debtor_entries[1].line_number

        expect(deal.creditor_entries.size).to eq 1
        new_creditor_entry = deal.creditor_entries.first
        expect(new_creditor_entry.id).to eq old_creditor_entry.id
        expect(new_creditor_entry.amount).to eq old_creditor_entry.amount
        expect(new_creditor_entry.account_id).to eq old_creditor_entry.account_id
        expect(new_creditor_entry.user_id).to eq old_creditor_entry.user_id
        expect(new_creditor_entry.line_number).to eq old_creditor_entry.line_number
      end
    end

  end

  describe "#destroy" do
    let(:complex_deal_contains_same_accounts) {
      deal = new_complex_deal(3, 1, {:taro_food => '1,300'},{:taro_cache => '-1,000', :taro_bank => '-300'})
      deal.save!
      deal
    }
    it "重複のある複数明細が削除できる" do
      expect{complex_deal_contains_same_accounts.destroy}.not_to raise_error
    end
  end

end
