# Hosting Configurations

ROOT_URL                               = ENV['ROOT_URL']                                || "http://localhost:3000"
SUPPORT_EMAIL_ADDRESS                  = ENV['SUPPORT_EMAIL_ADDRESS']                   || "support@example.com"

SKIP_MAIL                              = (ENV['SKIP_MAIL']                              || 'true') == 'true'

GOOGLE_ANALYTICS_CODE                  = ENV['GOOGLE_ANALYTICS_CODE']                   if ENV['GOOGLE_ANALYTICS_CODE']

KOZUCHI_SSL                            = (ENV['KOZUCHI_SSL']                            || 'false') == 'true'
LOGIN_ENGINE_SALT                      = ENV['LOGIN_ENGINE_SALT']                       || "koban"

PERSONAL_INFO_POLICY_SHOW              = (ENV['PERSONAL_INFO_POLICY_SHOW']              || 'false') == 'true'
PERSONAL_INFO_POLICY_HOST              = ENV['PERSONAL_INFO_POLICY_HOST']               || "http://localhost:3000"
PERSONAL_INFO_POLICY_PATH              = ENV['PERSONAL_INFO_POLICY_PATH']               || "/personalinfomationpolicy"
PERSONAL_INFO_POLICY_TITLE             = ENV['PERSONAL_INFO_POLICY_TITLE']              || "個人情報の取扱いについて"
PERSONAL_INFO_POLICY_CACHE_EXPIRE_DAYS = (ENV['PERSONAL_INFO_POLICY_CACHE_EXPIRE_DAYS'] || '1').to_i
PERSONAL_INFO_POLICY_TIMEOUT_SECONDS   = (ENV['PERSONAL_INFO_POLICY_TIMEOUT_SECONDS']   || '20').to_i
PRIVACY_POLICY_SHOW                    = (ENV['PRIVACY_POLICY_SHOW']                    || 'false') == 'true'
PRIVACY_POLICY_HOST                    = ENV['PRIVACY_POLICY_HOST']                     || "http://localhost:3000"
PRIVACY_POLICY_PATH                    = ENV['PRIVACY_POLICY_PATH']                     || "/privacypolicy"
PRIVACY_POLICY_CACHE_EXPIRE_DAYS       = (ENV['PRIVACY_POLICY_CACHE_EXPIRE_DAYS']       || '1').to_i
PRIVACY_POLICY_TIMEOUT_SECONDS         = (ENV['PRIVACY_POLICY_TIMEOUT_SECONDS']         || '20').to_i
