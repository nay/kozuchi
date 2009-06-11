require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe SingleLogin do
  before(:each) do
    @valid_attributes = {
    }
  end

  it "should create a new instance given valid attributes" do
    SingleLogin.create!(@valid_attributes)
  end
end
