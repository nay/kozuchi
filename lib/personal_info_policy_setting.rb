class PersonalInfoPolicySetting
  attr_accessor :title
  include Contents

  def initialize
    @show  = PERSONAL_INFO_POLICY_SHOW  if defined? PERSONAL_INFO_POLICY_SHOW
    @title = PERSONAL_INFO_POLICY_TITLE if defined? PERSONAL_INFO_POLICY_TITLE
    @host  = PERSONAL_INFO_POLICY_HOST  if defined? PERSONAL_INFO_POLICY_HOST
    @path  = PERSONAL_INFO_POLICY_PATH  if defined? PERSONAL_INFO_POLICY_PATH
    @cache_expire_days = PERSONAL_INFO_POLICY_CACHE_EXPIRE_DAYS if defined? PERSONAL_INFO_POLICY_CACHE_EXPIRE_DAYS
    @timeout_seconds = PERSONAL_INFO_POLICY_TIMEOUT_SECONDS if defined? PERSONAL_INFO_POLICY_TIMEOUT_SECONDS
    @cache_key = 'personal_info_policy'
  end

end
