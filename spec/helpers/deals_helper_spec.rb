require 'spec_helper'

describe DealsHelper, type: :helper do
  describe "#deals_list_path" do
    context "date: に日のある年月日を指定したとき" do
      it "その日で絞った一覧のパスを返す" do
        expect(helper.deals_list_path(date: Date.new(2026, 9, 26))).to eq "/deals/2026/9/26"
      end
    end

    context "year:, month: だけを指定したとき" do
      it "月の一覧のパスを返す" do
        expect(helper.deals_list_path(year: 2026, month: 9)).to eq "/deals/2026/9"
      end
    end

    context "account_id: も指定したとき" do
      it "その口座の一覧のパスを返す" do
        expect(helper.deals_list_path(date: VagueDate.new(2026, 9, 26), account_id: 1)).to eq "/accounts/1/deals/2026/9/26"
        expect(helper.deals_list_path(date: VagueDate.new(2026, 9), account_id: 1)).to eq "/accounts/1/deals/2026/9"
      end
    end

    context "date: と year: を同時に指定したとき" do
      it "ArgumentError になる" do
        expect { helper.deals_list_path(date: Date.new(2026, 9, 26), year: 2026) }.to raise_error(ArgumentError)
      end
    end
  end
end
