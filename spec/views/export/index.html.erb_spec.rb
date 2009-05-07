require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/export/index" do
  before(:each) do
    assigns[:export_file_name] = "kozuchi-2009-04-01"
    render 'export/index'
  end
  
  it "should be success" do
    response.should be_success
  end
end
