require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../controller_spec_helper')

describe AssetsController, type: :controller do
  fixtures :users, :accounts
  before do
    login_as :taro
  end
  describe "index" do
    context "口座が十分あるとき" do
      it "monthlyにリダイレクトされる" do
        get :index
        expect(response).to redirect_to(monthly_assets_path(:year => Time.zone.today.year, :month => Time.zone.today.month))
      end
    end
    context "口座がないとき" do
      before do
        Account::Base.where(user_id: @current_user.id).delete_all # destroy_all だと記入が邪魔で削除できない　関連スタートは dependent destroy 依存
      end
      it "エラーページが表示される" do
        get :index
        expect(response).to be_successful
      end
    end
  end
  describe "monthly" do
    it "成功する" do
      get :monthly, params: {:year => Time.zone.today.year.to_s, :month => Time.zone.today.month.to_s}
      expect(response).to be_successful
    end
  end
end