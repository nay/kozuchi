class PersonalInfoPolicySetting
  attr_accessor :show, :title, :partial_name

  def initialize
    @show  = PERSONAL_INFO_POLICY_SHOW if defined? PERSONAL_INFO_POLICY_SHOW
    @title = PERSONAL_INFO_POLICY_TITLE if defined? PERSONAL_INFO_POLICY_TITLE
    @partial_name = PERSONAL_INFO_POLICY_PARTIAL_NAME if defined? PERSONAL_INFO_POLICY_PARTIAL_NAME
  end
end
