require "spec_helper"

describe "記入パターン", js: true do
  self.use_transactional_fixtures = false
  fixtures :users, :accounts, :preferences
  set_fixture_class  :accounts => Account::Base

  include_context "太郎 logged in"

  describe "登録" do
    before do
      visit "/settings/deals/patterns"
      click_link "新規登録"
    end

    it "登録フォームが表示される" do
      expect(page).to have_css("input#deal_pattern_name")
    end

    describe "実行" do
      # TODO: 別のバリエーションも追加したい
      context "サマリー統一モードで完全なシンプルな記入をいれたとき" do
        before do
          page.find("a.unify_summary").click
          fill_in "コード", with: "HML"
          fill_in "名前", with: "ハニーミルクラテ"
          fill_in :deal_pattern_summary, with: "ハニーミルクラテ"
          fill_in :deal_pattern_debtor_entries_attributes_0_amount, with: "470"
          select "食費", from: :deal_pattern_debtor_entries_attributes_0_account_id
          fill_in :deal_pattern_creditor_entries_attributes_0_reversed_amount, with: "470"
          select "現金", from: :deal_pattern_creditor_entries_attributes_0_account_id
          click_button "登録"
        end
        it { expect(flash_notice).to have_content "記入パターン「HML ハニーミルクラテ」を登録しました。" }
        # TODO: 入れたとおりの内容が入っていることの確認
      end
    end

    describe "記入欄を増やす" do
      before do
        click_link "記入欄を増やす"
      end

      it { expect(page.all(:xpath, "//input[contains(@class, 'amount')][contains(@name, 'deal_pattern[debtor_entries_attributes]')]").size).to eq 6 }
    end
  end

  describe "更新" do
    let!(:deal_pattern) { FactoryGirl.create(:deal_pattern) }

    before do
      visit "/settings/deals/patterns"
      click_link "001 給料"
    end

    it "更新フォームが表示される" do
      expect(page).to have_css("input#deal_pattern_name")
    end

    describe "実行" do
      before do
        fill_in "コード", with: "002"
        fill_in "名前", with: "サラリー"
        click_button "更新"
      end
      it { expect(flash_notice).to have_content "記入パターン「002 サラリー」を更新しました。" }
      # TODO: 変更したとおりの内容が入っていることの確認
    end

    describe "記入欄を増やす" do
      before do
        click_link "記入欄を増やす"
      end

      it { expect(page.all(:xpath, "//input[contains(@class, 'amount')][contains(@name, 'deal_pattern[debtor_entries_attributes]')]").size).to eq 6 }
    end
  end

end
