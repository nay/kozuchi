class AccountLink < ActiveRecord::Base
  belongs_to :account, :class_name => "Account::Base", :foreign_key => "account_id"
  belongs_to :target_user, :foreign_key => "target_user_id", :class_name => "User"

  attr_accessor :skip_requesting
  
  after_create :create_target_request
  before_update {raise "Not Supported"}
  after_destroy :destroy_target_request

  attr_protected :user_id, :target_user_id, :target_ex_account_id

  validates_presence_of :target_ex_account_id, :user_id, :target_user_id
  # TODO: target_ex_account_idを最後にもっていくと検証実行で変な不具合ぽい失敗が発生する(Rails2.1)

  validates_uniqueness_of :target_ex_account_id, :scope => [:target_user_id, :account_id]

  # AcocuntProxyまたはAccountオブジェクトを返す
  def target_account
    raise AssociatedObjectMissingError, "no target_user for #{self.inspect}. target_user_id = #{self.target_user_id}" unless target_user
    target_user.account(self.target_ex_account_id)
  end

  private
  def create_target_request
#    p "create_target_request"
    if skip_requesting
      self.skip_requesting = nil
      return
    end
#    p "check friend"
    # テストなどでtarget_userレコードを用意しないケースもあるので、存在しなければ書き込みしない。
    # 存在してもフレンドでなければ書き込みしない。
    # TODO: target_userがProxyなら反対側のデータを見るようにしたい
    return unless target_user && target_user.friend?(user_id)
#    p "going to do create_link_request"
    target_account.create_link_request(user_id, account_id)
  end

  def destroy_target_request
    User.find(self.target_user_id).account(self.target_ex_account_id).destroy_link_request(self.user_id, self.account_id)
  end

end
