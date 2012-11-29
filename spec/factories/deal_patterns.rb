# -*- encoding : utf-8 -*-
# 
# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :deal_pattern, :class => Pattern::Deal do
    user_id Fixtures.identify(:taro)
    code "001"
    name "給料"
  end
end
