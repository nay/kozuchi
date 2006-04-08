class AccountEntry < ActiveRecord::Base
  belongs_to :deal
  belongs_to :account
end
