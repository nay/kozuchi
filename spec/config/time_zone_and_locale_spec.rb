require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

# config.time_zone は config/initializers 以下に書くと反映されないため、
# 設定が実際に効いていることを検証する
describe 'タイムゾーンとロケールの設定' do
  it 'Time.zone が Tokyo、デフォルトロケールが ja になっている' do
    expect(Time.zone.name).to eq 'Tokyo'
    expect(I18n.default_locale).to eq :ja
  end
end
