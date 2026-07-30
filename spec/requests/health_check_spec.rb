require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe 'ヘルスチェック', type: :request do
  describe 'GET /up' do
    it '200 を返す' do
      get '/up'
      expect(response).to have_http_status(:ok)
    end
  end
end
