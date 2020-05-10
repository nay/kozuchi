require "spec_helper"

describe "記入パターン", js: true, type: :feature do
  fixtures :users, :accounts, :preferences

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
      before do
        page.find("a.unify_summary").click
        fill_in "コード", with: "HML"
        fill_in "名前", with: "ハニーミルクラテ"
        fill_in :deal_pattern_summary, with: summary
        fill_in :deal_pattern_debtor_entries_attributes_0_amount, with: "470"
        select "食費", from: :deal_pattern_debtor_entries_attributes_0_account_id
        fill_in :deal_pattern_creditor_entries_attributes_0_reversed_amount, with: "470"
        select "現金", from: :deal_pattern_creditor_entries_attributes_0_account_id
        click_button "登録"
      end

      # TODO: 別のバリエーションも追加したい
      context "サマリー統一モードで完全なシンプルな記入をいれたとき" do
        let(:summary) { "ハニーミルクラテ" }

        it { expect(flash_notice).to have_content "記入パターン「HML ハニーミルクラテ」を登録しました。" }
        # TODO: 入れたとおりの内容が入っていることの確認

        context "摘要が100文字のとき" do
          let(:summary) { "a" * 100 }
          it "サマリーが短縮されたとのメッセージが表示される" do
            expect(flash_notice).to have_content "長すぎる摘要を64文字に短縮しました。"
          end
        end
      end
    end

    describe "記入欄を増やす" do
      before do
        click_link "記入欄を増やす"
      end

      # 0 はじまり
      it { expect(page).to be_has_xpath("//input[contains(@class, 'amount')][contains(@name, 'deal_pattern[debtor_entries_attributes][5]')]") }
    end

    # TODO: DRY （更新側と）
    describe "パターン呼び出し" do
      let!(:deal_pattern) { create(:deal_pattern, code: "001") }

      # ここがきちんと動作していないかほかの理由により数値が入らないのでスキップ
      before do
        fill_in "パターン呼出", with: "001"
        page.find('#pattern_keyword').send_keys('Enter')
      end

      xit {
        expect(page.find('#deal_pattern_code').value).to eq "" # コードは埋められない
        expect(page.find('#deal_pattern_name').value).to eq "" # 名前は埋められない
        expect(page.find('#deal_pattern_debtor_entries_attributes_0_amount').value).to eq deal_pattern.debtor_entries.first.amount.to_s
      }
    end
  end

  describe "更新" do
    let!(:deal_pattern) { create(:deal_pattern) }

    before do
      visit "/settings/deals/patterns"
      click_link "001 給料"
    end

    it "更新フォームが表示される" do
      expect(page).to have_css("input#deal_pattern_name")
    end

    describe "実行" do
      let(:summary) { "給与（更新後）" }
      before do
        fill_in "コード", with: "002"
        fill_in "名前", with: "サラリー"
        fill_in :deal_pattern_creditor_entries_attributes_0_summary, with: summary
        click_button "更新"
      end
      it { expect(flash_notice).to have_content "記入パターン「002 サラリー」を更新しました。" }
      # TODO: 変更したとおりの内容が入っていることの確認

      context "摘要が100文字のとき" do
        let(:summary) { "a" * 100 }
        it "サマリーが短縮されたとのメッセージが表示される" do
          expect(flash_notice).to have_content "長すぎる摘要を64文字に短縮しました。"
        end
      end
    end

    describe "記入欄を増やす" do
      before do
        click_link "記入欄を増やす"
      end

      # 0はじまり
      it { expect(page).to be_has_xpath("//input[contains(@class, 'amount')][contains(@name, 'deal_pattern[debtor_entries_attributes][5]')]") }
    end

    # TODO: パターン呼び出し 不具合があるのか、この状態から片面だけのパターンを呼び出すとうまくいかない

  end
end
