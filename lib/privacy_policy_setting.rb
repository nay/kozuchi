class PrivacyPolicySetting
  include Contents

  def initialize
    @show  = PRIVACY_POLICY_SHOW  if defined? PRIVACY_POLICY_SHOW
    @host  = PRIVACY_POLICY_HOST  if defined? PRIVACY_POLICY_HOST
    @path  = PRIVACY_POLICY_PATH  if defined? PRIVACY_POLICY_PATH
    @cache_expire_days = PRIVACY_POLICY_CACHE_EXPIRE_DAYS if defined? PRIVACY_POLICY_CACHE_EXPIRE_DAYS
    @timeout_seconds = PRIVACY_POLICY_TIMEOUT_SECONDS if defined? PRIVACY_POLICY_TIMEOUT_SECONDS
    @cache_key = 'privacy_policy'
  end
end
