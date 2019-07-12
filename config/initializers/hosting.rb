# -*- encoding : utf-8 -*-

# Please change this file to your hosting.rb.

# Hosting Configurations

SUPPORT_EMAIL_ADDRESS = ENV['SUPPORT_EMAIL_ADDRESS'] || "support@example.com"
ROOT_URL              = ENV['ROOT_URL'] || "http://localhost:3000"
LOGIN_ENGINE_SALT     = ENV['LOGIN_ENGINE_SALT'] || "koban"
KOZUCHI_SSL           = (ENV['KOZUCHI_SSL'] || 'false') == 'true'

SKIP_MAIL             = (ENV['SKIP_MAIL'] || 'true') == 'true'
# GOOGLE_ANALYTICS_CODE = 'XXXXXX-X'

# USER_MANAGEMENT_TYPE
#   open : Anybody can make new user.
#   closed : Admin function only.
KOZUCHI_USER_MANAGEMENT_TYPE = ENV['KOZUCHI_USER_MANAGEMENT_TYPE'] || 'open'

# Remove # if you don't want to display news.
# DISPLAY_NEWS = false

# Personal information policy settings
PERSONAL_INFO_POLICY_SHOW    = (ENV['PERSONAL_INFO_POLICY_SHOW'] || 'false') == 'true'
PERSONAL_INFO_POLICY_HOST    = ENV['PERSONAL_INFO_POLICY_HOST'] || "http://localhost:3000"
PERSONAL_INFO_POLICY_PATH    = ENV['PERSONAL_INFO_POLICY_PATH'] || "/personalinfomationpolicy"
PERSONAL_INFO_POLICY_TITLE   = ENV['PERSONAL_INFO_POLICY_TITLE'] || "個人情報の取扱いについて"
PERSONAL_INFO_POLICY_CACHE_EXPIRE_DAYS = (ENV['PERSONAL_INFO_POLICY_CACHE_EXPIRE_DAYS'] || '1').to_i
PERSONAL_INFO_POLICY_TIMEOUT_SECONDS = (ENV['PERSONAL_INFO_POLICY_TIMEOUT_SECONDS'] || '20').to_i

# Privacy policy settings
PRIVACY_POLICY_SHOW    = (ENV['PRIVACY_POLICY_SHOW'] || 'false') == 'true'
PRIVACY_POLICY_HOST    = ENV['PRIVACY_POLICY_HOST'] || "http://localhost:3000"
PRIVACY_POLICY_PATH    = ENV['PRIVACY_POLICY_PATH'] || "/privacypolicy"
PRIVACY_POLICY_CACHE_EXPIRE_DAYS = (ENV['PRIVACY_POLICY_CACHE_EXPIRE_DAYS'] || '1').to_i
PRIVACY_POLICY_TIMEOUT_SECONDS = (ENV['PRIVACY_POLICY_TIMEOUT_SECONDS'] || '20').to_i

# Used as Kozuchi::Application.config.secret_key_base. Please change the value below.
if ENV['KOZUCHI_SECRET_KEY_BASE']
  KOZUCHI_SECRET_KEY_BASE = ENV['KOZUCHI_SECRET_KEY_BASE']
end
