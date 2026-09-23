require 'spec_helper'

# カレンダーは収支表・貸借対照表・資産表・記入画面で共通のため、収支表の画面で確認する
describe "カレンダー", js: true, type: :feature do
  fixtures :users, :accounts, :preferences

  include_context "太郎 logged in"

  context "2026年3月を表示しているとき" do
    before do
      visit monthly_profit_and_loss_path(year: 2026, month: 3)
    end

    it "7か月前の2025年8月から2026年7月までを年の見出しを分けて並べ、3月を選択中として表示する" do
      expect(page).to have_css("td.year", count: 2)
      expect(page).to have_css("td.year[colspan='5']", text: "2025")
      expect(page).to have_css("td.year[colspan='7']", text: "2026")
      expect(page).to have_css("td.month", count: 12)
      expect(page).to have_css("td.month:first-of-type#month_2025_8")
      expect(page).to have_css("td.month:last-of-type#month_2026_7")
      expect(page).to have_css("td.selected_month#month_2026_3", text: "3月")
    end

    context "<< を押したとき" do
      before do
        find("#prev_year").click
      end

      it "2025年3月の画面に移る" do
        expect(page).to have_content("2025年3月末日の収支表")
      end
    end

    context ">> を押したとき" do
      before do
        find("#next_year").click
      end

      it "2027年3月の画面に移る" do
        expect(page).to have_content("2027年3月末日の収支表")
      end
    end
  end

  context "2026年8月を表示しているとき" do
    before do
      visit monthly_profit_and_loss_path(year: 2026, month: 8)
    end

    it "2026年1月から12月までを、1つの年の見出しの下に並べる" do
      expect(page).to have_css("td.year", count: 1)
      expect(page).to have_css("td.year[colspan='12']", text: "2026")
      expect(page).to have_css("td.month:first-of-type#month_2026_1")
      expect(page).to have_css("td.month:last-of-type#month_2026_12")
    end
  end
end
