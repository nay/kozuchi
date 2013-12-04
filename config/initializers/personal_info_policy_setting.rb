class PersonalInfoPolicySetting
  SETTING = YAML.load_file("#{Rails.root}/config/personal_info_policy.yml")
  
  attr_accessor :show, :title, :partial_filename

  def initialize
    @show = SETTING["show"]
    @title = SETTING["title"]
    @partial_filename = SETTING["partial_filename"]
  end
end

