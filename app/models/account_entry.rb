class AccountEntry < ActiveRecord::Base
  belongs_to :deal
  belongs_to :account
  validates_presence_of :amount
end
